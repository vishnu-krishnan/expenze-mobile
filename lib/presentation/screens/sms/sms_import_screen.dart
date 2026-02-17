import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../data/models/category.dart';
import '../../../data/models/expense.dart';
import '../../../data/services/sms_service.dart';
import '../../../data/services/api_service.dart';

class DetectedExpense {
  final String id;
  final String raw;
  String name;
  double amount;
  int? categoryId;
  String priority;
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
  final _apiService = ApiService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rawTextController.dispose();
    super.dispose();
  }

  Future<void> _syncFromInbox() async {
    setState(() => _isLoading = true);

    try {
      final importedIds =
          await context.read<ExpenseProvider>().getImportedSmsIds();
      final messages = await _smsService.getRecentSms(months: 6);
      final List<DetectedExpense> newExpenses = [];

      for (var msg in messages) {
        final smsId = 'sms-${msg.id ?? DateTime.now().millisecondsSinceEpoch}';

        // Skip if already imported
        if (importedIds.contains(smsId)) continue;

        final parsed = _smsService.parseExpenseFromSms(msg.body ?? '');
        if (parsed != null) {
          newExpenses.add(DetectedExpense(
            id: smsId,
            raw: parsed['raw'],
            name: parsed['merchant'],
            amount: parsed['amount'],
            date: msg.date,
          ));
        }
      }

      setState(() {
        _detectedExpenses = [...newExpenses, ..._detectedExpenses];
        final seen = <String>{};
        _detectedExpenses.retainWhere((e) => seen.add(e.raw));
      });

      if (newExpenses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No new transaction SMS found'),
                behavior: SnackBarBehavior.floating),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found ${newExpenses.length} new transactions'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      _smsService.logger.e('Sync error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _parseManualSms() {
    final text = _rawTextController.text;
    if (text.isEmpty) return;

    setState(() => _isLoading = true);

    final lines = text.split('\n').where((l) => l.trim().length > 10).toList();
    final List<DetectedExpense> results = [];

    for (var line in lines) {
      final parsed = _smsService.parseExpenseFromSms(line);
      if (parsed != null) {
        results.add(DetectedExpense(
          id: 'manual-${DateTime.now().millisecondsSinceEpoch}',
          raw: parsed['raw'],
          name: parsed['merchant'],
          amount: parsed['amount'],
        ));
      }
    }

    setState(() {
      _detectedExpenses = results;
      _isLoading = false;
    });
  }

  Future<void> _aiParse() async {
    final text = _rawTextController.text;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please paste some SMS content first')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.aiParseSms(text);
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> expensesJson = data['expenses'] ?? [];
        final catProvider = context.read<CategoryProvider>();
        final categories = catProvider.categories;

        final results = expensesJson.asMap().entries.map((entry) {
          final json = entry.value;
          final index = entry.key;
          final suggestion =
              json['categorySuggestion']?.toString().toLowerCase() ?? '';
          int? matchedId;
          for (var cat in categories) {
            if (suggestion.contains(cat.name.toLowerCase()) ||
                cat.name.toLowerCase().contains(suggestion)) {
              matchedId = cat.id;
              break;
            }
          }

          return DetectedExpense(
            id: 'ai-$index-${DateTime.now().millisecondsSinceEpoch}',
            raw: json['rawText'] ?? 'AI parsed',
            name: json['name'] ?? 'Unknown',
            amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
            categoryId: matchedId,
            priority: json['priority'] ?? 'MEDIUM',
          );
        }).toList();

        setState(() => _detectedExpenses = results);
      }
    } catch (e) {
      _smsService.logger.e('AI Parse error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importAll() async {
    final provider = context.read<ExpenseProvider>();

    int successCount = 0;
    for (var i = 0; i < _detectedExpenses.length; i++) {
      final item = _detectedExpenses[i];
      if (item.amount == 0 || item.isSuccess) continue;

      setState(() => _detectedExpenses[i].isSaving = true);
      try {
        final date = item.date ?? DateTime.now();
        // Format month key as YYYY-MM
        final monthKey =
            "${date.year}-${date.month.toString().padLeft(2, '0')}";

        final expense = Expense(
          monthKey: monthKey,
          categoryId: item.categoryId,
          name: item.name,
          plannedAmount: 0, // Set to 0 so it counts as Unplanned
          actualAmount: item.amount,
          priority: item.priority,
          isPaid: true,
          paidDate: date.toIso8601String(),
          notes: 'SMS_ID:${item.id}',
        );
        await provider.addExpense(expense);
        setState(() => _detectedExpenses[i].isSuccess = true);
        successCount++;
      } catch (e) {
        _smsService.logger.e('Error importing item ${item.name}: $e');
      } finally {
        setState(() => _detectedExpenses[i].isSaving = false);
      }
    }

    if (successCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported $successCount transactions'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
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
      floatingActionButton: _detectedExpenses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _importAll,
              backgroundColor: Colors.white,
              icon:
                  const Icon(LucideIcons.checkSquare, color: AppTheme.primary),
              label: const Text('Import All',
                  style: TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildAutoSyncTab(Color textColor, Color secondaryTextColor) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.softShadow,
              border:
                  Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.smartphone,
                    size: 48, color: AppTheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Auto-detect from Inbox',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'We scan your messages locally to find recent transaction alerts from your bank.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: secondaryTextColor, fontSize: 13),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _syncFromInbox,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.zap, size: 18),
                    label: Text(_isLoading ? 'Scanning...' : 'Start Auto Scan'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => _showClearSmsDialog(context),
                  icon: const Icon(LucideIcons.trash2,
                      size: 16, color: AppTheme.danger),
                  label: const Text('Clear Previously Imported Data',
                      style: TextStyle(color: AppTheme.danger)),
                ),
              ],
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
        Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paste SMS Content',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 12),
                TextField(
                  controller: _rawTextController,
                  maxLines: 4,
                  decoration: AppTheme.inputDecoration(
                      'Paste one or more bank messages...',
                      LucideIcons.alignLeft,
                      context: context),
                  style: TextStyle(color: textColor, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _parseManualSms,
                        icon: const Icon(LucideIcons.search, size: 18),
                        label: const Text('Lite Scan'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppTheme.primary.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _aiParse,
                        icon: const Icon(LucideIcons.sparkles, size: 18),
                        label: const Text('AI Analysis'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
          itemCount: _detectedExpenses.length,
          itemBuilder: (context, index) {
            final expense = _detectedExpenses[index];
            return _buildDetectedCard(expense, index, catProvider.categories,
                textColor, secondaryTextColor);
          },
        );
      },
    );
  }

  Widget _buildDetectedCard(DetectedExpense expense, int index,
      List<Category> categories, Color textColor, Color secondaryTextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: expense.isSuccess
            ? AppTheme.success.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.05
                    : 0.1)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
            color: expense.isSuccess
                ? AppTheme.success.withValues(alpha: 0.3)
                : AppTheme.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.indianRupee,
                    size: 18, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor)),
                    Text(
                      expense.raw.length > 50
                          ? '${expense.raw.substring(0, 50)}...'
                          : expense.raw,
                      style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 11,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${expense.amount.toStringAsFixed(0)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: expense.categoryId,
                  dropdownColor: Theme.of(context).cardTheme.color,
                  items: categories
                      .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name,
                              style:
                                  TextStyle(fontSize: 13, color: textColor))))
                      .toList(),
                  onChanged: expense.isSuccess
                      ? null
                      : (val) => setState(
                          () => _detectedExpenses[index].categoryId = val),
                  decoration: AppTheme.inputDecoration(
                      'Category', LucideIcons.tag,
                      context: context),
                ),
              ),
              const SizedBox(width: 12),
              if (expense.isSaving)
                const SizedBox(
                    width: 40,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)))
              else if (expense.isSuccess)
                const Icon(LucideIcons.checkCircle,
                    color: AppTheme.success, size: 28)
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.trash2,
                        color: AppTheme.danger, size: 18),
                    onPressed: () =>
                        setState(() => _detectedExpenses.removeAt(index)),
                  ),
                ),
            ],
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
