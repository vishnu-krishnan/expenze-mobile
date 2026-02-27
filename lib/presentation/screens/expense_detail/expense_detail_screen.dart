import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/expense.dart';
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
    final isDark = themeProvider.isDarkMode;

    final categoryProvider = context.read<CategoryProvider>();
    final category = categoryProvider.categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => categoryProvider.categories.first,
    );

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
            _buildCustomAppBar(context, textColor, category),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildHeroSection(
                        context, category, textColor, secondaryTextColor),
                    const SizedBox(height: 32),
                    _buildInfoGrid(context, textColor, secondaryTextColor),
                    const SizedBox(height: 24),
                    if (expense.notes != null && expense.notes!.isNotEmpty)
                      _buildEnhancedNotes(
                          context, textColor, secondaryTextColor),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(
      BuildContext context, Color textColor, dynamic category) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 48), // Spacer to balance share button
            Text(
              'Transaction',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            IconButton(
              onPressed: () {
                final amount = expense.actualAmount > 0
                    ? expense.actualAmount
                    : expense.plannedAmount;
                final date = expense.paidDate != null
                    ? DateFormat('dd MMM yyyy, hh:mm a')
                        .format(DateTime.parse(expense.paidDate!))
                    : DateFormat('MMMM yyyy')
                        .format(DateTime.parse('${expense.monthKey}-01'));

                final text = '''
Expense Details
---------------
Item: ${expense.name}
Amount: ₹${amount.toStringAsFixed(0)}
Category: ${category.name}
Date: $date
Status: ${expense.isPaid ? 'Paid' : 'Planned'}
Notes: ${expense.notes ?? 'N/A'}

Shared via Expenze App
''';
                SharePlus.instance.share(ShareParams(text: text));
              },
              icon: Icon(LucideIcons.share2, color: textColor, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, dynamic category,
      Color textColor, Color secondaryTextColor) {
    final amount =
        expense.actualAmount > 0 ? expense.actualAmount : expense.plannedAmount;
    final isImported = expense.notes?.contains('SMS_ID') ?? false;

    return Column(
      children: [
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.primary.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
            Container(
              height: 85,
              width: 85,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                shape: BoxShape.circle,
                boxShadow: AppTheme.softShadow,
              ),
              alignment: Alignment.center,
              child: Text(
                category.icon ?? '💰',
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          expense.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category.name,
              style: TextStyle(
                  fontSize: 15,
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w600),
            ),
            if (isImported) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'IMPORTED',
                  style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 32),
        FittedBox(
          child: Text(
            '₹${amount.toLocaleString()}',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: (expense.isPaid ? AppTheme.success : AppTheme.secondary)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (expense.isPaid ? AppTheme.success : AppTheme.secondary)
                  .withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            expense.isPaid ? 'CONFIRMED SPENT' : 'PLANNED PAYMENT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: expense.isPaid ? AppTheme.success : AppTheme.secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(
      BuildContext context, Color textColor, Color secondaryTextColor) {
    final date = expense.paidDate != null
        ? DateTime.parse(expense.paidDate!)
        : DateTime.parse('${expense.monthKey}-01');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          _buildDetailTile(
            LucideIcons.calendar,
            'Transaction Date',
            DateFormat('EEEE, dd MMMM yyyy, hh:mm a').format(date),
            textColor,
            secondaryTextColor,
          ),
          _buildDivider(context),
          _buildDetailTile(
            LucideIcons.creditCard,
            'Method',
            expense.paymentMode.toUpperCase(),
            textColor,
            secondaryTextColor,
            badge: expense.paymentMode != 'Other',
          ),
          _buildDivider(context),
          _buildDetailTile(
            LucideIcons.shieldAlert,
            'Priority Level',
            expense.priority.toUpperCase(),
            textColor,
            secondaryTextColor,
            color: _getPriorityColor(expense.priority),
          ),
          if (expense.plannedAmount > 0) ...[
            _buildDivider(context),
            _buildDetailTile(
              LucideIcons.target,
              'Planned Amount',
              '₹${expense.plannedAmount.toLocaleString()}',
              textColor,
              secondaryTextColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value,
      Color textColor, Color secondaryTextColor,
      {Color? color, bool badge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (color ?? AppTheme.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color ?? AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                if (badge)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(value,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary)),
                  )
                else
                  Text(value,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
        height: 1,
        color: AppTheme.getTextColor(context).withValues(alpha: 0.05));
  }

  Widget _buildEnhancedNotes(
      BuildContext context, Color textColor, Color secondaryTextColor) {
    // Extract metadata if it's an SMS import
    String displayNotes = expense.notes!;
    String? metadata;
    if (displayNotes.contains('SMS_ID:')) {
      final parts = displayNotes.split(' | MSG:');
      if (parts.length > 1) {
        metadata = parts[0];
        displayNotes = parts[1];
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.fileText,
                  size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text('Notes & Metadata',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: textColor)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayNotes,
            style: TextStyle(
                fontSize: 14,
                color: textColor,
                height: 1.6,
                fontWeight: FontWeight.w500),
          ),
          if (metadata != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                metadata,
                style: TextStyle(
                    fontSize: 10,
                    color: secondaryTextColor,
                    fontFamily: 'monospace'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return AppTheme.danger;
      case 'MEDIUM':
        return AppTheme.warning;
      case 'LOW':
        return AppTheme.success;
      default:
        return AppTheme.primary;
    }
  }
}

extension DetailDoubleExtension on double {
  String toLocaleString() {
    return toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
