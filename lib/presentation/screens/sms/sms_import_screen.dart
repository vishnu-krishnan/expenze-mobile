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
  bool isSaving;
  bool isSuccess;

  DetectedExpense({
    required this.id,
    required this.raw,
    required this.name,
    required this.amount,
    this.categoryId,
    this.priority = 'MEDIUM',
    this.isSaving = false,
    this.isSuccess = false,
  });
}

class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  final _rawTextController = TextEditingController();
  List<DetectedExpense> _detectedExpenses = [];
  bool _isLoading = false;
  final _smsService = SmsService();
  final _apiService = ApiService();

  Future<void> _syncFromInbox() async {
    setState(() => _isLoading = true);

    try {
      final messages = await _smsService.getRecentSms(limit: 50);
      final List<DetectedExpense> newExpenses = [];

      for (var msg in messages) {
        final parsed = _smsService.parseExpenseFromSms(msg.body ?? '');
        if (parsed != null) {
          newExpenses.add(DetectedExpense(
            id: 'sms-${msg.id ?? DateTime.now().millisecondsSinceEpoch}',
            raw: parsed['raw'],
            name: parsed['merchant'],
            amount: parsed['amount'],
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

  void _parseSms() {
    final text = _rawTextController.text;
    if (text.isEmpty) return;

    setState(() => _isLoading = true);

    final lines = text.split('\n').where((l) => l.trim().length > 10).toList();
    final results = lines.asMap().entries.map((entry) {
      final line = entry.value;
      final index = entry.key;

      final amountRegex = RegExp(
          r'(?:Rs\.?|INR|debited for Rs)\s*?([\d,]+(?:\.\d{2})?)',
          caseSensitive: false);
      final amountMatch = amountRegex.firstMatch(line);
      final amount = amountMatch != null
          ? double.parse(amountMatch.group(1)!.replaceAll(',', ''))
          : 0.0;

      final merchantRegex = RegExp(
          r'(?:at|to|for|from|merchant:?)\s+([A-Z0-9\s&]{3,24})',
          caseSensitive: false);
      final merchantMatch = merchantRegex.firstMatch(line);
      final merchant = merchantMatch != null
          ? merchantMatch.group(1)!.trim()
          : 'Unknown Merchant';

      return DetectedExpense(
          id: 'lite-$index', raw: line, name: merchant, amount: amount);
    }).toList();

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
    final currentMonth = provider.currentMonthKey;

    for (var i = 0; i < _detectedExpenses.length; i++) {
      final item = _detectedExpenses[i];
      if (item.categoryId == null || item.amount == 0 || item.isSuccess)
        continue;
      setState(() => _detectedExpenses[i].isSaving = true);
      try {
        final expense = Expense(
          monthKey: currentMonth,
          categoryId: item.categoryId,
          name: item.name,
          plannedAmount: item.amount,
          actualAmount: item.amount,
          priority: item.priority,
          isPaid: true,
        );
        await provider.addExpense(expense);
        setState(() => _detectedExpenses[i].isSuccess = true);
      } catch (e) {
        _smsService.logger.e('Error importing: $e');
      } finally {
        setState(() => _detectedExpenses[i].isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      decoration: themeProvider.isDarkMode
          ? AppTheme.darkBackgroundDecoration
          : AppTheme.backgroundDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Smart SMS Import')),
        body: Consumer<CategoryProvider>(
          builder: (context, catProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputSection(),
                  if (_detectedExpenses.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Detected Expenses',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        ElevatedButton.icon(
                          onPressed: _importAll,
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text('Import All'),
                          style: AppTheme.primaryButtonStyle.copyWith(
                            padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._detectedExpenses.asMap().entries.map((entry) =>
                        _buildDetectedCard(
                            entry.value, entry.key, catProvider.categories)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.mail, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Text('Paste SMS Content',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rawTextController,
            maxLines: 6,
            decoration: AppTheme.inputDecoration(
                    'Paste transaction messages...', LucideIcons.smartphone)
                .copyWith(prefixIcon: null),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _syncFromInbox,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(_isLoading ? 'Syncing...' : 'Sync from Inbox'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _parseSms,
                  icon: const Icon(LucideIcons.zap, size: 18),
                  label: const Text('Lite Parse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.textSecondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _aiParse,
                  icon: const Icon(LucideIcons.sparkles, size: 18),
                  label: const Text('AI Parse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedCard(
      DetectedExpense expense, int index, List<Category> categories) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: expense.isSuccess
            ? AppTheme.success.withValues(alpha: 0.1)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
            color: expense.isSuccess
                ? AppTheme.success.withValues(alpha: 0.3)
                : AppTheme.border.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(expense.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Text(
                '₹${expense.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.primary),
              ),
            ],
          ),
          Text(
            expense.raw,
            style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontStyle: FontStyle.italic),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: expense.categoryId,
                  items: categories
                      .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name,
                              style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: expense.isSuccess
                      ? null
                      : (val) => setState(
                          () => _detectedExpenses[index].categoryId = val),
                  decoration:
                      AppTheme.inputDecoration('Category', LucideIcons.tag),
                ),
              ),
              const SizedBox(width: 12),
              if (expense.isSaving)
                const CircularProgressIndicator(strokeWidth: 2)
              else if (expense.isSuccess)
                const Icon(LucideIcons.checkCircle,
                    color: AppTheme.success, size: 24)
              else
                IconButton(
                  icon: const Icon(LucideIcons.trash2,
                      color: AppTheme.danger, size: 20),
                  onPressed: () =>
                      setState(() => _detectedExpenses.removeAt(index)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
