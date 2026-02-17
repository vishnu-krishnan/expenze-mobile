import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/theme_provider.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);
    final categoryProvider = context.read<CategoryProvider>();
    final category = categoryProvider.categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => categoryProvider.categories.first,
    );

    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgPrimaryDark : AppTheme.bgPrimary,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: Column(
          children: [
            AppBar(
              title: const Text('Transaction Details'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              automaticallyImplyLeading: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainCard(
                        context, category, textColor, secondaryTextColor),
                    const SizedBox(height: 24),
                    _buildDetailsSection(
                        context, textColor, secondaryTextColor),
                    const SizedBox(height: 24),
                    if (expense.notes != null && expense.notes!.isNotEmpty)
                      _buildNotesSection(
                          context, textColor, secondaryTextColor),
                    const SizedBox(height: 32),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, dynamic category, Color textColor,
      Color secondaryTextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              category.icon ?? '💰',
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            expense.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            category.name,
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '₹${expense.actualAmount > 0 ? expense.actualAmount.toStringAsFixed(2) : expense.plannedAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (expense.isPaid ? AppTheme.success : AppTheme.secondary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              expense.isPaid ? 'PAID' : 'PLANNED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: expense.isPaid ? AppTheme.success : AppTheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(
      BuildContext context, Color textColor, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            LucideIcons.calendar,
            'Date',
            expense.paidDate != null
                ? DateFormat('dd MMM yyyy')
                    .format(DateTime.parse(expense.paidDate!))
                : DateFormat('MMMM yyyy')
                    .format(DateTime.parse('${expense.monthKey}-01')),
            textColor,
            secondaryTextColor,
          ),
          const Divider(height: 32),
          _buildDetailRow(
            LucideIcons.target,
            'Planned Amount',
            '₹${expense.plannedAmount.toStringAsFixed(2)}',
            textColor,
            secondaryTextColor,
          ),
          const Divider(height: 32),
          _buildDetailRow(
            LucideIcons.trendingUp,
            'Actual Amount',
            '₹${expense.actualAmount.toStringAsFixed(2)}',
            textColor,
            secondaryTextColor,
          ),
          const Divider(height: 32),
          _buildDetailRow(
            LucideIcons.shieldAlert,
            'Priority',
            expense.priority,
            textColor,
            secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      Color textColor, Color secondaryTextColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: secondaryTextColor)),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection(
      BuildContext context, Color textColor, Color secondaryTextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.fileText,
                  size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text('Notes',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            expense.notes!,
            style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Edit logic
              Navigator.pop(context);
            },
            icon: const Icon(LucideIcons.edit3, size: 18),
            label: const Text('Edit Transaction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.trash2, color: AppTheme.danger),
            onPressed: () {
              context.read<ExpenseProvider>().deleteExpense(expense.id!);
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }
}
