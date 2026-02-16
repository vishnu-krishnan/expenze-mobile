import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/regular_payment_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/theme_provider.dart';
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

  Future<void> _markAsPaid(RegularPayment payment) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final paymentProvider = context.read<RegularPaymentProvider>();

    final controller = TextEditingController(
        text: payment.defaultPlannedAmount.toStringAsFixed(0));

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pay ${payment.name}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).cardTheme.color,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the final amount paid:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: AppTheme.inputDecoration(
                  'Amount', LucideIcons.indianRupee,
                  context: context),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final amount =
          double.tryParse(controller.text) ?? payment.defaultPlannedAmount;

      final expense = Expense(
        monthKey: expenseProvider.currentMonthKey,
        categoryId: payment.categoryId,
        name: payment.name,
        plannedAmount: payment.defaultPlannedAmount,
        actualAmount: amount,
        isPaid: true,
        paidDate: DateTime.now().toIso8601String(),
        notes: 'Recurring payment: ${payment.name}',
      );

      await expenseProvider.addExpense(expense);

      final updatedPayment = payment.copyWith(
        status: 'Paid',
        statusDescription:
            'Last paid on ${DateFormat('dd MMM').format(DateTime.now())} for ₹${amount.toInt()}',
      );

      await paymentProvider.updatePayment(updatedPayment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment recorded for ${payment.name}'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: themeProvider.isDarkMode
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: Column(
          children: [
            AppBar(
              title: Text('Regular Payments',
                  style:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
            ),
            Expanded(
              child: Consumer2<RegularPaymentProvider, CategoryProvider>(
                builder: (context, provider, categoryProvider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.payments.isEmpty) {
                    return _buildEmptyState(secondaryTextColor);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    itemCount: provider.payments.length,
                    itemBuilder: (context, index) {
                      final payment = provider.payments[index];
                      return _buildPaymentCard(
                          payment, provider, textColor, secondaryTextColor);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPaymentDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(Color secondaryTextColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.repeat,
              size: 64, color: secondaryTextColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No active subscriptions',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: secondaryTextColor)),
          const Text('Manage your recurring bills here'),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
      RegularPayment payment,
      RegularPaymentProvider provider,
      Color textColor,
      Color secondaryTextColor) {
    final bool isPaidThisMonth = payment.status?.toLowerCase() == 'paid';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(LucideIcons.repeat,
                    size: 20, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payment.name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor)),
                    Text(payment.categoryName ?? 'Miscellaneous',
                        style:
                            TextStyle(color: secondaryTextColor, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${payment.defaultPlannedAmount.toInt()}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: textColor)),
                  Text(payment.frequency.toLowerCase(),
                      style:
                          TextStyle(fontSize: 11, color: secondaryTextColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 12, color: secondaryTextColor),
              const SizedBox(width: 4),
              Text(
                'Starts: ${DateFormat('dd MMM yyyy').format(DateTime.parse(payment.startDate))}',
                style: TextStyle(fontSize: 11, color: secondaryTextColor),
              ),
              if (payment.endDate != null) ...[
                const Spacer(),
                Icon(LucideIcons.calendarX,
                    size: 12, color: secondaryTextColor),
                const SizedBox(width: 4),
                Text(
                  'Ends: ${DateFormat('dd MMM yyyy').format(DateTime.parse(payment.endDate!))}',
                  style: TextStyle(fontSize: 11, color: secondaryTextColor),
                ),
              ],
            ],
          ),
          if (payment.durationMonths != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Period: ${payment.durationMonths} months',
                style: TextStyle(
                    fontSize: 11,
                    color: secondaryTextColor,
                    fontStyle: FontStyle.italic),
              ),
            ),
          if (payment.status != null && payment.status!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isPaidThisMonth ? AppTheme.success : AppTheme.primary)
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                          isPaidThisMonth
                              ? LucideIcons.checkCircle
                              : LucideIcons.info,
                          size: 14,
                          color: isPaidThisMonth
                              ? AppTheme.success
                              : AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Status: ${payment.status}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPaidThisMonth
                                ? AppTheme.success
                                : AppTheme.primary),
                      ),
                    ],
                  ),
                  if (payment.statusDescription != null &&
                      payment.statusDescription!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 20),
                      child: Text(
                        payment.statusDescription!,
                        style:
                            TextStyle(fontSize: 11, color: secondaryTextColor),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed:
                      isPaidThisMonth ? null : () => _markAsPaid(payment),
                  icon: const Icon(LucideIcons.banknote, size: 14),
                  label: Text(isPaidThisMonth ? 'Paid' : 'Mark as Paid',
                      style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPaidThisMonth
                        ? AppTheme.success.withValues(alpha: 0.1)
                        : AppTheme.primary,
                    foregroundColor:
                        isPaidThisMonth ? AppTheme.success : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        _showPaymentDialog(context, payment: payment),
                    icon: Icon(LucideIcons.edit2,
                        size: 16, color: secondaryTextColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => provider.deletePayment(payment.id!),
                    icon: const Icon(LucideIcons.trash2,
                        size: 16, color: AppTheme.danger),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, {RegularPayment? payment}) {
    final nameController = TextEditingController(text: payment?.name ?? '');
    final amountController = TextEditingController(
        text: payment?.defaultPlannedAmount.toString() ?? '');
    final notesController = TextEditingController(text: payment?.notes ?? '');
    final statusController = TextEditingController(text: payment?.status ?? '');
    final statusDescController =
        TextEditingController(text: payment?.statusDescription ?? '');
    final durationController =
        TextEditingController(text: payment?.durationMonths?.toString() ?? '');

    int? selectedCategoryId = payment?.categoryId;
    String frequency = payment?.frequency ?? 'MONTHLY';
    DateTime startDate =
        payment != null ? DateTime.parse(payment.startDate) : DateTime.now();
    DateTime? endDate =
        payment?.endDate != null ? DateTime.parse(payment!.endDate!) : null;

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

          void updateEndDateFromDuration() {
            final durationStr = durationController.text;
            if (durationStr.isNotEmpty) {
              final duration = int.tryParse(durationStr);
              if (duration != null && duration > 0) {
                setModalState(() {
                  endDate = DateTime(startDate.year, startDate.month + duration,
                      startDate.day);
                });
              }
            }
          }

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: modalBgColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      payment == null
                          ? 'Enroll Payment'
                          : 'Update Bill Details',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: AppTheme.inputDecoration(
                        'Subscription Name', LucideIcons.creditCard,
                        context: context),
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedCategoryId,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: AppTheme.inputDecoration(
                              'Amount', LucideIcons.indianRupee,
                              context: context),
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: frequency,
                          dropdownColor: modalBgColor,
                          items: const [
                            DropdownMenuItem(
                                value: 'MONTHLY', child: Text('Monthly')),
                            DropdownMenuItem(
                                value: 'WEEKLY', child: Text('Weekly')),
                            DropdownMenuItem(
                                value: 'YEARLY', child: Text('Yearly')),
                          ],
                          onChanged: (val) =>
                              setModalState(() => frequency = val!),
                          decoration: AppTheme.inputDecoration(
                              'Cycle', LucideIcons.repeat,
                              context: context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Schedule',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(LucideIcons.calendar,
                              color: AppTheme.primary, size: 20),
                          title: const Text('Start Date',
                              style: TextStyle(fontSize: 11)),
                          subtitle: Text(
                              DateFormat('dd MMM yyyy').format(startDate),
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setModalState(() => startDate = picked);
                              updateEndDateFromDuration();
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          decoration: AppTheme.inputDecoration(
                              'Period (Months)', LucideIcons.timer,
                              context: context),
                          style: TextStyle(color: textColor, fontSize: 13),
                          onChanged: (val) => updateEndDateFromDuration(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(LucideIcons.calendarX,
                        color: AppTheme.danger, size: 20),
                    title: const Text('End Date (Calculated)',
                        style: TextStyle(fontSize: 11)),
                    subtitle: Text(
                        endDate != null
                            ? DateFormat('dd MMM yyyy').format(endDate!)
                            : 'Indefinite',
                        style: TextStyle(
                            color: endDate != null
                                ? textColor
                                : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            endDate ?? startDate.add(const Duration(days: 365)),
                        firstDate: startDate,
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() {
                          endDate = picked;
                          durationController
                              .clear(); // Clear duration if manually picking end date
                        });
                      }
                    },
                    trailing: endDate != null
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 14),
                            onPressed: () =>
                                setModalState(() => endDate = null),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Status & Logs',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: statusController,
                    decoration: AppTheme.inputDecoration(
                        'Current Status (e.g. Paid, Overdue)', LucideIcons.info,
                        context: context),
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: statusDescController,
                    decoration: AppTheme.inputDecoration(
                        'Status Description/Reason', LucideIcons.alignLeft,
                        context: context),
                    style: TextStyle(color: textColor),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty ||
                            selectedCategoryId == null) return;

                        final provider = context.read<RegularPaymentProvider>();
                        final newPayment = RegularPayment(
                          id: payment?.id,
                          name: nameController.text,
                          categoryId: selectedCategoryId!,
                          defaultPlannedAmount:
                              double.tryParse(amountController.text) ?? 0,
                          frequency: frequency,
                          startDate: DateFormat('yyyy-MM-dd').format(startDate),
                          endDate: endDate != null
                              ? DateFormat('yyyy-MM-dd').format(endDate!)
                              : null,
                          durationMonths: int.tryParse(durationController.text),
                          isActive: true,
                          notes: notesController.text,
                          status: statusController.text,
                          statusDescription: statusDescController.text,
                        );

                        if (payment == null) {
                          await provider.addPayment(newPayment);
                        } else {
                          await provider.updatePayment(newPayment);
                        }

                        if (mounted) Navigator.pop(context);
                      },
                      child: Text(payment == null
                          ? 'Enroll Payment'
                          : 'Update Details'),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
