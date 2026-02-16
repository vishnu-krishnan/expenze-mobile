import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/regular_payment_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../data/models/category.dart' as model;

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
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgPrimaryDark : AppTheme.bgPrimary,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto-pay Bills',
                        style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 14,
                            letterSpacing: 0.5)),
                    Text('Recurring Payments',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -1)),
                  ],
                ),
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
                      padding: const EdgeInsets.fromLTRB(26, 0, 26, 120),
                      itemCount: provider.payments.length,
                      itemBuilder: (context, index) {
                        final payment = provider.payments[index];
                        return _buildPaymentCard(payment, categoryProvider,
                            textColor, secondaryTextColor);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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
          child: const Icon(LucideIcons.plus,
              color: AppTheme.primaryDark, size: 30),
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
              color: AppTheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.repeat,
                size: 64, color: AppTheme.primary.withOpacity(0.4)),
          ),
          const SizedBox(height: 24),
          Text('No recurring bills yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: secondaryTextColor)),
          const SizedBox(height: 8),
          Text('Add your subscriptions to track them automatically',
              style: TextStyle(
                  fontSize: 13, color: secondaryTextColor.withOpacity(0.7))),
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
                      .withOpacity(0.1),
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
              Text('₹${payment.defaultPlannedAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: textColor)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: secondaryTextColor.withOpacity(0.05),
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

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    int? selectedCategoryId;
    DateTime startDate = DateTime.now();
    DateTime? endDate;

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
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Text('Setup Recurring Bill',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 32),
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
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: AppTheme.inputDecoration(
                        'Bill Name', LucideIcons.tag,
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
                            if (picked != null)
                              setModalState(() => startDate = picked);
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
                            if (picked != null)
                              setModalState(() => endDate = picked);
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
                            amountController.text.isEmpty) return;

                        final amount =
                            double.tryParse(amountController.text) ?? 0.0;
                        if (amount <= 0) return;

                        await context
                            .read<RegularPaymentProvider>()
                            .addPayment(RegularPayment(
                              categoryId: selectedCategoryId!,
                              name: nameController.text,
                              defaultPlannedAmount: amount,
                              frequency: 'MONTHLY',
                              startDate:
                                  DateFormat('yyyy-MM-dd').format(startDate),
                              endDate: endDate != null
                                  ? DateFormat('yyyy-MM-dd').format(endDate!)
                                  : null,
                              durationMonths: null,
                              isActive: true,
                            ));
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18))),
                      child: const Text('Save',
                          style: TextStyle(
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
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
