import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/regular_payment_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/expense_provider.dart';
import '../../../data/models/category.dart' as model;
import '../../../data/models/expense.dart';

class RegularPaymentsScreen extends StatefulWidget {
  const RegularPaymentsScreen({super.key});

  @override
  State<RegularPaymentsScreen> createState() => _RegularPaymentsScreenState();
}

class _RegularPaymentsScreenState extends State<RegularPaymentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegularPaymentProvider>().loadPayments();
    });
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
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              expandedHeight: 100,
              floating: true,
              pinned: false,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.zero,
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 10, 26, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Regular Expenses',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: -1)),
                    ],
                  ),
                ),
              ),
            ),
            if (context.watch<RegularPaymentProvider>().isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 26),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
              sliver: Consumer3<RegularPaymentProvider, CategoryProvider,
                  ExpenseProvider>(
                builder: (context, provider, categoryProvider, expenseProvider,
                    child) {
                  if (provider.payments.isEmpty && !provider.isLoading) {
                    return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(secondaryTextColor));
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final payment = provider.payments[index];
                        return _buildPaymentCard(payment, categoryProvider,
                            textColor, secondaryTextColor);
                      },
                      childCount: provider.payments.length,
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Consumer2<RegularPaymentProvider, ExpenseProvider>(
                builder: (context, rProvider, eProvider, _) =>
                    _buildSummaryFooter(rProvider.payments, eProvider.expenses,
                        textColor, secondaryTextColor),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: FloatingActionButton(
          heroTag: 'regular_payments_fab',
          onPressed: () => _showAddDialog(context),
          backgroundColor: AppTheme.primary,
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(LucideIcons.plus, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color secondaryTextColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.repeat,
                size: 64, color: AppTheme.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 24),
          Text('No recurring bills yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: secondaryTextColor)),
          const SizedBox(height: 8),
          Text(
              'Netflix, rent, gym — add them here\nso they never sneak up on you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(RegularPayment payment, CategoryProvider catProvider,
      Color textColor, Color secondaryTextColor) {
    final cat = catProvider.categories.firstWhere(
        (c) => c.id == payment.categoryId,
        orElse: () => model.Category(
            id: 0, name: 'General', icon: '📁', color: '#79D2C1'));

    final nextDate =
        payment.endDate != null ? DateTime.parse(payment.endDate!) : null;
    final isOverdue = nextDate != null && nextDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Color(int.parse(
                          (cat.color ?? '#79D2C1').replaceFirst('#', '0xff')))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(cat.icon ?? '📁',
                    style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payment.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: textColor)),
                    Text(payment.frequency.toLowerCase(),
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${payment.defaultPlannedAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: textColor)),
                  GestureDetector(
                    onTap: () => _showAddDialog(context, payment: payment),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(LucideIcons.edit3,
                          size: 16, color: secondaryTextColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: secondaryTextColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDateInfo(
                    'Start Date', payment.startDate, secondaryTextColor),
                if (payment.endDate != null)
                  _buildDateInfo('Next Due', payment.endDate!,
                      isOverdue ? AppTheme.danger : AppTheme.primary),
                if (payment.durationMonths != null)
                  _buildPeriodInfo('Period', '${payment.durationMonths} Mo',
                      secondaryTextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, String dateStr, Color color) {
    final date = DateTime.parse(dateStr);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(DateFormat('MMM dd, yyyy').format(date),
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildPeriodInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildSummaryFooter(List<RegularPayment> payments,
      List<Expense> expenses, Color textColor, Color secondaryTextColor) {
    if (payments.isEmpty) return const SizedBox.shrink();

    final activePayments = payments.where((p) => p.isActive).toList();
    if (activePayments.isEmpty) return const SizedBox.shrink();

    double totalCommitment = 0.0;
    double paidAmount = 0.0;

    for (final payment in activePayments) {
      totalCommitment += payment.defaultPlannedAmount;

      // Check if this regular payment is "paid" in the current month's expenses
      // A payment is considered paid if an expense with the same name exists
      final isPaid = expenses.any((e) =>
          e.name.trim().toLowerCase() == payment.name.trim().toLowerCase() &&
          e.categoryId == payment.categoryId);

      if (isPaid) {
        paidAmount += payment.defaultPlannedAmount;
      }
    }

    final pendingAmount = totalCommitment - paidAmount;
    final isAllCleared = pendingAmount <= 0 && totalCommitment > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isAllCleared
            ? AppTheme.success.withValues(alpha: 0.1)
            : AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isAllCleared
                ? AppTheme.success.withValues(alpha: 0.2)
                : AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text('Total Monthly Commitments',
              style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '₹${totalCommitment.toStringAsFixed(0)}',
            style: TextStyle(
                color: isAllCleared ? AppTheme.success : AppTheme.primary,
                fontWeight: FontWeight.w900,
                fontSize: 32),
          ),
          const SizedBox(height: 12),
          if (isAllCleared)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.checkCircle,
                    color: AppTheme.success, size: 16),
                const SizedBox(width: 8),
                Text(
                  'You\'re all caught up! 🎉',
                  style: TextStyle(
                      color: AppTheme.success.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ],
            )
          else
            Text(
              'Still pending: ₹${pendingAmount.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          const SizedBox(height: 4),
          Text(
            isAllCleared
                ? 'Bills paid. Wallet intact. Go treat yourself (a little).'
                : '₹${pendingAmount.toStringAsFixed(0)} in recurring commitments still waiting. You\'ve got this.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: secondaryTextColor.withValues(alpha: 0.8),
                fontSize: 11,
                height: 1.4),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, {RegularPayment? payment}) {
    final nameController = TextEditingController(text: payment?.name);
    final amountController = TextEditingController(
        text: payment != null
            ? payment.defaultPlannedAmount.toStringAsFixed(0)
            : '');
    final notesController = TextEditingController(text: payment?.notes);
    int? selectedCategoryId = payment?.categoryId;
    DateTime startDate =
        payment != null ? DateTime.parse(payment.startDate) : DateTime.now();
    DateTime? endDate =
        payment?.endDate != null ? DateTime.parse(payment!.endDate!) : null;

    String priority = payment?.priority ?? 'MEDIUM';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final modalBgColor = isDark ? AppTheme.bgCardDark : Colors.white;
          final textColor = AppTheme.getTextColor(context);
          final categories = context.read<CategoryProvider>().categories;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 40,
              top: 32,
              left: 32,
              right: 32,
            ),
            decoration: BoxDecoration(
              color: modalBgColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Text(
                      payment == null
                          ? 'Setup Regular Expense'
                          : 'Edit Regular Expense',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 32),
                  DropdownButtonFormField<int>(
                    initialValue: selectedCategoryId,
                    dropdownColor: modalBgColor,
                    items: categories
                        .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name,
                                style: TextStyle(color: textColor))))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedCategoryId = val),
                    decoration: AppTheme.inputDecoration(
                        'Category', LucideIcons.layoutGrid,
                        context: context),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: AppTheme.inputDecoration(
                        'Expense Name', LucideIcons.tag,
                        context: context),
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: notesController,
                    decoration: AppTheme.inputDecoration(
                        'Description (Optional)', LucideIcons.fileText,
                        context: context),
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: AppTheme.inputDecoration(
                        'Amount', LucideIcons.indianRupee,
                        context: context),
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: priority,
                    dropdownColor: modalBgColor,
                    items: ['LOW', 'MEDIUM', 'HIGH']
                        .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p, style: TextStyle(color: textColor))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => priority = val);
                      }
                    },
                    decoration: AppTheme.inputDecoration(
                        'Priority', LucideIcons.alertCircle,
                        context: context),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setModalState(() => startDate = picked);
                            }
                          },
                          child: _buildPickerBox(
                              'Start Date',
                              DateFormat('MMM dd, yyyy').format(startDate),
                              isDark),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? startDate,
                              firstDate: startDate,
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setModalState(() => endDate = picked);
                            }
                          },
                          onLongPress: () =>
                              setModalState(() => endDate = null),
                          child: _buildPickerBox(
                              'End Date (Optional)',
                              endDate != null
                                  ? DateFormat('MMM dd, yyyy').format(endDate!)
                                  : 'No End Date',
                              isDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty ||
                            selectedCategoryId == null ||
                            amountController.text.isEmpty) {
                          return;
                        }

                        final amount =
                            double.tryParse(amountController.text) ?? 0.0;
                        if (amount <= 0) return;

                        final provider = context.read<RegularPaymentProvider>();

                        if (payment == null) {
                          await provider.addPayment(RegularPayment(
                            categoryId: selectedCategoryId!,
                            name: nameController.text,
                            defaultPlannedAmount: amount,
                            notes: notesController.text,
                            frequency: 'MONTHLY',
                            startDate:
                                DateFormat('yyyy-MM-dd').format(startDate),
                            endDate: endDate != null
                                ? DateFormat('yyyy-MM-dd').format(endDate!)
                                : null,
                            durationMonths: null,
                            isActive: true,
                            priority: priority,
                          ));
                        } else {
                          await provider.updatePayment(payment.copyWith(
                            categoryId: selectedCategoryId!,
                            name: nameController.text,
                            defaultPlannedAmount: amount,
                            notes: notesController.text,
                            startDate:
                                DateFormat('yyyy-MM-dd').format(startDate),
                            endDate: endDate != null
                                ? DateFormat('yyyy-MM-dd').format(endDate!)
                                : null,
                            priority: priority,
                          ));
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18))),
                      child: Text(
                          payment == null ? 'Lock It In' : 'Save Changes',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPickerBox(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
