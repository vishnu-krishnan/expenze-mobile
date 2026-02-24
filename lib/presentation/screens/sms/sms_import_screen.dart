import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/category.dart';
import '../../../data/models/expense.dart';
import '../../../data/services/sms_service.dart';
import '../../../data/services/api_service.dart';
import 'package:dio/dio.dart';

class DetectedExpense {
  final String id;
  final String raw;
  String name;
  double amount;
  int? categoryId;
  String priority;
  String paymentMode;
  final DateTime? date;
  bool isSaving;
  bool isSuccess;

  DetectedExpense({
    required this.id,
    required this.raw,
    required this.name,
    required this.amount,
    this.categoryId,
    this.priority = 'MEDIUM',
    this.paymentMode = 'Other',
    this.date,
    this.isSaving = false,
    this.isSuccess = false,
  });
}

class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen>
    with SingleTickerProviderStateMixin {
  final _rawTextController = TextEditingController();
  List<DetectedExpense> _detectedExpenses = [];
  bool _isLoading = false;
  final _smsService = SmsService();
  late TabController _tabController;
  DateTime? _lastRateLimitTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Automatically trigger sync on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncFromInbox();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rawTextController.dispose();
    super.dispose();
  }

  Future<void> _syncFromInbox() async {
    if (_lastRateLimitTime != null) {
      final diff = DateTime.now().difference(_lastRateLimitTime!);
      if (diff.inSeconds < 20) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'AI is cooling down. Please wait ${20 - diff.inSeconds}s...'),
              backgroundColor: AppTheme.warning,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<ExpenseProvider>();
      final importedIds = await provider.getImportedSmsIds();
      final importedBodies = await provider.getImportedSmsSignatures();
      final messages = await _smsService.getRecentSms(months: 6);

      final onScreenIds = _detectedExpenses.map((e) => e.id).toSet();
      final onScreenBodies = _detectedExpenses.map((e) => e.raw).toSet();
      final List<Map<String, dynamic>> potentialMessages = [];

      for (var msg in messages) {
        final body = msg.body?.trim() ?? '';
        if (body.isEmpty) continue;

        final smsId =
            'sms-${msg.id ?? msg.date?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';

        // Check ID OR Content against DB and current screen
        if (importedIds.contains(smsId) ||
            importedBodies.contains(body) ||
            onScreenIds.contains(smsId) ||
            onScreenBodies.contains(body)) {
          continue;
        }

        // Native pre-filter to drop generic non-expenses quickly
        final parsed = _smsService.parseExpenseFromSms(body);
        if (parsed != null) {
          potentialMessages.add({
            'id': smsId,
            'body': body,
            'date': msg.date,
          });
        }
      }

      // Use a batch of 20 to be extremely safe with free-tier rate limits (30 was still risky)
      final limitedToSend = potentialMessages.take(20).toList();

      if (limitedToSend.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No new transaction SMS found'),
                behavior: SnackBarBehavior.floating),
          );
        }
        return;
      }

      final buffer = StringBuffer();
      for (var item in limitedToSend) {
        buffer.writeln('[ID: ${item['id']}] ${item['body']}');
      }

      if (!mounted) return;
      final catProvider = context.read<CategoryProvider>();
      final categories = catProvider.categories;
      final categoryStrings = categories.map((c) => c.name).toList();

      final auth = context.read<AuthProvider>();
      final userName = auth.user?['full_name'] as String?;
      final aiProvider =
          auth.aiProvider == 'claude' ? AiProvider.claude : AiProvider.groq;

      final apiService = context.read<ApiService>();
      final response = await apiService.aiParseSms(
          buffer.toString(), categoryStrings,
          userName: userName, provider: aiProvider);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> expensesJson = data['expenses'] ?? [];
        final provider = context.read<ExpenseProvider>();
        final merchantMappings = await provider.getMerchantMappings();
        final List<DetectedExpense> newExpenses = [];

        for (var entry in expensesJson.asMap().entries) {
          final json = entry.value;
          final index = entry.key;
          final merchantName = json['name']?.toString() ?? 'Unknown';

          final suggestion =
              json['categorySuggestion']?.toString().toLowerCase() ?? '';
          int? matchedId;

          // Learning Layer: Use historical mapping if exists
          if (merchantMappings.containsKey(merchantName)) {
            matchedId = merchantMappings[merchantName];
          } else {
            // Fallback to AI suggestion
            for (var cat in categories) {
              if (suggestion.contains(cat.name.toLowerCase()) ||
                  cat.name.toLowerCase().contains(suggestion)) {
                matchedId = cat.id;
                break;
              }
            }
          }

          DateTime? parsedDate;
          if (json['date'] != null) {
            try {
              parsedDate = DateTime.parse(json['date']);
            } catch (_) {}
          }

          final rawIdInput = json['id']?.toString() ?? '';

          // Try to find the original item by exact ID match or by checking if the extracted ID is a suffix/prefix
          final originalItem = limitedToSend.firstWhere((item) {
            final itemId = item['id'].toString();
            return itemId == rawIdInput ||
                itemId.endsWith(rawIdInput) ||
                rawIdInput.endsWith(itemId);
          }, orElse: () => {});

          final DateTime? fallbackDate = originalItem['date'] as DateTime?;
          // CRITICAL: Prioritize message arrival time (fallbackDate) over AI-parsed date
          // to ensure accuracy, unless AI found a very specific valid date.
          final finalDate = parsedDate ?? fallbackDate ?? DateTime.now();

          final finalId = originalItem.containsKey('id')
              ? (originalItem['id'] as String)
              : 'ai-$index-${DateTime.now().millisecondsSinceEpoch}';

          final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;
          if (amount <= 0) continue;

          // Override AI priority with user rules for consistency
          String finalPriority = json['priority'] ?? 'MEDIUM';
          if (amount <= 500) {
            finalPriority = 'MEDIUM';
          } else if (amount > 500) {
            finalPriority = 'HIGH';
          }

          newExpenses.add(DetectedExpense(
            id: finalId,
            raw: json['rawText'] ?? 'AI parsed',
            name: merchantName,
            amount: amount,
            categoryId: matchedId,
            priority: finalPriority,
            paymentMode: 'Other',
            date: finalDate,
          ));
        }

        setState(() {
          _detectedExpenses = [...newExpenses, ..._detectedExpenses];
          final seen = <String>{};
          _detectedExpenses.retainWhere((e) => seen.add(e.raw));
        });

        if (mounted) {
          final hasMore = potentialMessages.length > limitedToSend.length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Found ${newExpenses.length} new transactions.${hasMore ? ' Tap Rescan to find more.' : ''}'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      _smsService.logger.e('Sync error: $e');
      if (mounted) {
        String errorMsg = 'Error analyzing SMS. Please try again.';

        if (e is DioException) {
          if (e.response?.statusCode == 429) {
            _lastRateLimitTime = DateTime.now();
            errorMsg =
                'AI limit reached. System is cooling down for 15 seconds.';
          } else if (e.type == DioExceptionType.connectionTimeout) {
            errorMsg = 'Connection timed out. Check your internet.';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _aiParse() async {
    final text = _rawTextController.text;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please paste some SMS content first')));
      return;
    }

    if (_lastRateLimitTime != null) {
      final diff = DateTime.now().difference(_lastRateLimitTime!);
      if (diff.inSeconds < 20) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'AI is cooling down. Please wait ${20 - diff.inSeconds}s...'),
              backgroundColor: AppTheme.warning,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final catProvider = context.read<CategoryProvider>();
      final categories = catProvider.categories;
      final categoryStrings = categories.map((c) => c.name).toList();

      final auth = context.read<AuthProvider>();
      final userName = auth.user?['full_name'] as String?;
      final aiProvider =
          auth.aiProvider == 'claude' ? AiProvider.claude : AiProvider.groq;

      final apiService = context.read<ApiService>();
      final response = await apiService.aiParseSms(text, categoryStrings,
          userName: userName, provider: aiProvider);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> expensesJson = data['expenses'] ?? [];
        final provider = context.read<ExpenseProvider>();
        final merchantMappings = await provider.getMerchantMappings();

        final results = expensesJson.asMap().entries.map((entry) {
          final json = entry.value;
          final index = entry.key;
          final merchantName = json['name']?.toString() ?? 'Unknown';

          final suggestion =
              json['categorySuggestion']?.toString().toLowerCase() ?? '';
          int? matchedId;

          // Learning Layer: Use historical mapping if exists
          if (merchantMappings.containsKey(merchantName)) {
            matchedId = merchantMappings[merchantName];
          } else {
            // Fallback to AI suggestion
            for (var cat in categories) {
              if (suggestion.contains(cat.name.toLowerCase()) ||
                  cat.name.toLowerCase().contains(suggestion)) {
                matchedId = cat.id;
                break;
              }
            }
          }

          DateTime? parsedDate;
          if (json['date'] != null) {
            try {
              parsedDate = DateTime.parse(json['date']);
            } catch (_) {}
          }

          final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;

          // Apply User Priority Rules
          String finalPriority = json['priority'] ?? 'MEDIUM';
          if (amount <= 500) {
            finalPriority = 'MEDIUM';
          } else if (amount > 500) {
            finalPriority = 'HIGH';
          }

          return DetectedExpense(
            id: 'ai-$index-${DateTime.now().millisecondsSinceEpoch}',
            raw: json['rawText'] ?? 'AI parsed',
            name: merchantName,
            amount: amount,
            categoryId: matchedId,
            priority: finalPriority,
            date: parsedDate ??
                DateTime.now(), // Fallback to current time only for PASTED text
          );
        }).toList();

        setState(() => _detectedExpenses = results);
      }
    } catch (e) {
      _smsService.logger.e('AI Parse error: $e');
      if (mounted) {
        String errorMsg = 'AI error. Please try again.';
        if (e is DioException) {
          if (e.response?.statusCode == 429) {
            _lastRateLimitTime = DateTime.now();
            errorMsg = 'AI limit reached. Waiting 15s.';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importAll() async {
    final provider = context.read<ExpenseProvider>();
    final List<Expense> toImport = [];
    final List<int> indices = [];

    for (var i = 0; i < _detectedExpenses.length; i++) {
      final item = _detectedExpenses[i];
      if (item.amount == 0 || item.isSuccess) continue;

      final date = item.date ?? DateTime.now();
      final monthKey = "${date.year}-${date.month.toString().padLeft(2, '0')}";

      toImport.add(Expense(
        monthKey: monthKey,
        categoryId: item.categoryId,
        name: item.name,
        plannedAmount: 0.0,
        actualAmount: item.amount,
        priority: item.priority,
        paymentMode: item.paymentMode,
        isPaid: true,
        paidDate: date.toIso8601String(),
        createdAt: date.toIso8601String(),
        notes: 'SMS_ID:${item.id} | MSG:${item.raw}',
      ));
      indices.add(i);
      setState(() => _detectedExpenses[i].isSaving = true);
    }

    if (toImport.isEmpty) return;

    try {
      await provider.addExpenses(toImport);

      // LEARNING PHASE: Save merchant-to-category mappings
      for (var item in toImport) {
        if (item.categoryId != null) {
          await provider.upsertMerchantMapping(item.name, item.categoryId!);
        }
      }

      setState(() {
        final importedSet = indices.toSet();
        final remaining = <DetectedExpense>[];
        for (var i = 0; i < _detectedExpenses.length; i++) {
          if (!importedSet.contains(i)) {
            remaining.add(_detectedExpenses[i]);
          }
        }
        _detectedExpenses = remaining;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Successfully imported ${toImport.length} transactions'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _smsService.logger.e('Bulk import error: $e');
      setState(() {
        for (var idx in indices) {
          _detectedExpenses[idx].isSaving = false;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Smart Import',
                            style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 13,
                                letterSpacing: 0.5)),
                        Text('SMS Scanner',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                                letterSpacing: -1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              labelColor: AppTheme.primary,
              unselectedLabelColor: secondaryTextColor,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
              tabs: const [
                Tab(
                    text: 'Auto Sync',
                    icon: Icon(LucideIcons.refreshCw, size: 18)),
                Tab(
                    text: 'Manual Paste',
                    icon: Icon(LucideIcons.clipboard, size: 18)),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAutoSyncTab(textColor, secondaryTextColor),
                  _buildManualTab(textColor, secondaryTextColor),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _detectedExpenses.isEmpty
          ? null
          : Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL SELECTED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: secondaryTextColor,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${_detectedExpenses.fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _importAll,
                      icon: const Icon(LucideIcons.checkSquare, size: 18),
                      label: Text('Import ${_detectedExpenses.length} Items'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAutoSyncTab(Color textColor, Color secondaryTextColor) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _detectedExpenses.isEmpty ? null : 200,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: _detectedExpenses.isEmpty ? 24 : 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppTheme.softShadow,
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    if (_detectedExpenses.isEmpty) ...[
                      const Icon(LucideIcons.smartphone,
                          size: 40, color: AppTheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Auto-detect from Inbox',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'We scan locally to find bank transaction alerts.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: secondaryTextColor, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                    ] else
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.zap,
                                size: 16, color: AppTheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Scan Results',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        fontSize: 16)),
                                Text('${_detectedExpenses.length} items found',
                                    style: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_isLoading ||
                                    (_lastRateLimitTime != null &&
                                        DateTime.now()
                                                .difference(_lastRateLimitTime!)
                                                .inSeconds <
                                            20))
                                ? null
                                : _syncFromInbox,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(LucideIcons.refreshCw, size: 16),
                            label: Text(_isLoading
                                ? 'Scanning...'
                                : (_lastRateLimitTime != null &&
                                        DateTime.now()
                                                .difference(_lastRateLimitTime!)
                                                .inSeconds <
                                            20)
                                    ? 'Cooling Down...'
                                    : 'Rescan'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _showClearSmsDialog(context),
                          icon: const Icon(LucideIcons.trash2,
                              size: 20, color: AppTheme.danger),
                          tooltip: 'Clear Imported',
                        ),
                      ],
                    ),
                    if (_detectedExpenses.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(LucideIcons.info,
                              size: 14, color: secondaryTextColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI use is limited per scan for stability. Please rescan after importing to process more messages.',
                              style: TextStyle(
                                  fontSize: 10, color: secondaryTextColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildDetectedList(textColor, secondaryTextColor),
        ),
      ],
    );
  }

  Widget _buildManualTab(Color textColor, Color secondaryTextColor) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _detectedExpenses.isEmpty ? null : 200,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.softShadow,
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_detectedExpenses.isEmpty) ...[
                      Row(
                        children: [
                          const Icon(LucideIcons.clipboard,
                              size: 20, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text('Paste Messages',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _rawTextController,
                      maxLines: _detectedExpenses.isEmpty ? 4 : 2,
                      decoration: AppTheme.inputDecoration(
                        'Paste bank SMS here...',
                        LucideIcons.alignLeft,
                        context: context,
                      ).copyWith(
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.black12
                                : Colors.grey[50],
                      ),
                      style: TextStyle(color: textColor, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isLoading ||
                                (_lastRateLimitTime != null &&
                                    DateTime.now()
                                            .difference(_lastRateLimitTime!)
                                            .inSeconds <
                                        20))
                            ? null
                            : _aiParse,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(LucideIcons.sparkles, size: 16),
                        label: Text(_isLoading
                            ? 'Analyzing...'
                            : (_lastRateLimitTime != null &&
                                    DateTime.now()
                                            .difference(_lastRateLimitTime!)
                                            .inSeconds <
                                        20)
                                ? 'Cooling Down...'
                                : 'Analyze Text'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildDetectedList(textColor, secondaryTextColor),
        ),
      ],
    );
  }

  Widget _buildDetectedList(Color textColor, Color secondaryTextColor) {
    if (_detectedExpenses.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.listFilter,
                size: 48, color: secondaryTextColor.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No transactions detected yet',
                style: TextStyle(color: secondaryTextColor)),
          ],
        ),
      );
    }

    if (_isLoading && _detectedExpenses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<CategoryProvider>(
      builder: (context, catProvider, child) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: _detectedExpenses.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_detectedExpenses.length} TRANSACTIONS FOUND',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: secondaryTextColor.withValues(alpha: 0.5),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              );
            }
            final listIndex = index - 1;
            final expense = _detectedExpenses[listIndex];
            return Dismissible(
              key: Key(expense.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                setState(() => _detectedExpenses.removeAt(listIndex));
              },
              background: Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: const Icon(LucideIcons.trash2, color: Colors.white),
              ),
              child: _buildDetectedCard(expense, listIndex,
                  catProvider.categories, textColor, secondaryTextColor),
            );
          },
        );
      },
    );
  }

  Widget _buildDetectedCard(DetectedExpense expense, int index,
      List<Category> categories, Color textColor, Color secondaryTextColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: expense.isSuccess
              ? AppTheme.success.withValues(alpha: 0.3)
              : AppTheme.primary.withValues(alpha: 0.1),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date and Payment Mode
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppTheme.primary.withValues(alpha: 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.calendar,
                        size: 14, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      expense.date != null
                          ? DateFormat('dd MMM yyyy, hh:mm a')
                              .format(expense.date!)
                          : 'Unknown Date',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (expense.isSuccess)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.check,
                                size: 12, color: AppTheme.success),
                            SizedBox(width: 4),
                            Text('IMPORTED',
                                style: TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          expense.paymentMode.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Main Transaction Info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(expense.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: textColor,
                                letterSpacing: -0.5,
                              )),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (expense.priority == 'HIGH'
                                          ? AppTheme.danger
                                          : expense.priority == 'MEDIUM'
                                              ? AppTheme.warning
                                              : AppTheme.success)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  expense.priority,
                                  style: TextStyle(
                                    color: expense.priority == 'HIGH'
                                        ? AppTheme.danger
                                        : expense.priority == 'MEDIUM'
                                            ? AppTheme.warning
                                            : AppTheme.success,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${expense.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: textColor,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Original Message Box - Professional Look
                Text(
                  'SOURCE MESSAGE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: secondaryTextColor.withValues(alpha: 0.6),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                    ),
                  ),
                  child: Text(
                    expense.raw,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                      height: 1.5,
                      fontFamily: 'Roboto', // Modern standard font
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action Row: Category selection
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: expense.categoryId,
                        isExpanded: true,
                        dropdownColor: Theme.of(context).cardTheme.color,
                        items: categories
                            .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Row(
                                  children: [
                                    Text(c.icon ?? '❓',
                                        style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(c.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 13, color: textColor)),
                                    ),
                                  ],
                                )))
                            .toList(),
                        onChanged: expense.isSuccess
                            ? null
                            : (val) => setState(() =>
                                _detectedExpenses[index].categoryId = val),
                        decoration: AppTheme.inputDecoration(
                          'Category',
                          LucideIcons.tag,
                          context: context,
                        ).copyWith(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    if (expense.isSaving) ...[
                      const SizedBox(width: 12),
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    ] else if (!expense.isSuccess) ...[
                      TextButton(
                        onPressed: () =>
                            setState(() => _detectedExpenses.removeAt(index)),
                        child: const Text('Dismiss',
                            style: TextStyle(
                              color: AppTheme.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearSmsDialog(BuildContext context) {
    if (!mounted) return;

    final provider = context.read<ExpenseProvider>();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear imported SMS?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'This will delete all expenses imported from SMS for this month. You will need to re-scan to get them back.'),
            const SizedBox(height: 16),
            const Text('Type "CONFIRM" to proceed:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'CONFIRM',
                hintStyle: TextStyle(fontSize: 12),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (value) {
                // Force rebuild to update button state
                (context as Element).markNeedsBuild();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: confirmController,
            builder: (context, value, child) {
              return TextButton(
                onPressed: value.text == 'CONFIRM'
                    ? () async {
                        Navigator.pop(context);
                        await provider
                            .clearImportedExpenses(provider.currentMonthKey);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Imported SMS expenses cleared')),
                          );
                          // Trigger rescan automatically
                          _syncFromInbox();
                        }
                      }
                    : null,
                child: Text('Delete',
                    style: TextStyle(
                        color: value.text == 'CONFIRM'
                            ? AppTheme.danger
                            : Colors.grey)),
              );
            },
          ),
        ],
      ),
    );
  }
}
