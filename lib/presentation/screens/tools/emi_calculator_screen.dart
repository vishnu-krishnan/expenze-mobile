import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';

class EmiCalculatorScreen extends StatefulWidget {
  const EmiCalculatorScreen({super.key});

  @override
  State<EmiCalculatorScreen> createState() => _EmiCalculatorScreenState();
}

class _EmiCalculatorScreenState extends State<EmiCalculatorScreen> {
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _tenureController = TextEditingController();

  double? _emi;
  double? _totalInterest;
  double? _totalPayment;
  bool _tenureInYears = true; // toggle: years / months

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  void _calculate() {
    final principal = double.tryParse(_principalController.text.replaceAll(',', ''));
    final annualRate = double.tryParse(_rateController.text);
    final tenureRaw = double.tryParse(_tenureController.text);

    if (principal == null || annualRate == null || tenureRaw == null) {
      setState(() {
        _emi = null;
        _totalInterest = null;
        _totalPayment = null;
      });
      return;
    }

    final months = _tenureInYears ? (tenureRaw * 12).round() : tenureRaw.round();
    final monthlyRate = annualRate / 12 / 100;

    double emi;
    if (monthlyRate == 0) {
      emi = principal / months;
    } else {
      final pow = math_pow(1 + monthlyRate, months);
      emi = principal * monthlyRate * pow / (pow - 1);
    }

    setState(() {
      _emi = emi;
      _totalPayment = emi * months;
      _totalInterest = _totalPayment! - principal;
    });
  }

  double math_pow(double base, int exp) => pow(base, exp).toDouble();

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)} L';
    return '₹${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.getTextColor(context);
    final secColor = AppTheme.getTextColor(context, isSecondary: true);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: Colors.transparent,
              systemOverlayStyle: AppTheme.headerOverlayStyle,
              automaticallyImplyLeading: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              expandedHeight: 110,
              collapsedHeight: 110,
              toolbarHeight: 110,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.zero,
                background: Container(
                  decoration: AppTheme.headerDecoration(context),
                  padding: EdgeInsets.fromLTRB(
                      26, MediaQuery.of(context).padding.top + 10, 26, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('EMI Calculator',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1)),
                          Text('Plan your loan before you sign.',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body ────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Input card
                  _card(
                    isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Loan Details', textColor),
                        const SizedBox(height: 16),

                        // Principal
                        _inputField(
                          controller: _principalController,
                          label: 'Loan Amount (₹)',
                          icon: LucideIcons.indianRupee,
                          hint: 'e.g. 500000',
                          context: context,
                          onChanged: (_) => _calculate(),
                          inputType: const TextInputType.numberWithOptions(decimal: true),
                          formatter: FilteringTextInputFormatter.allow(
                              RegExp(r'[\d,.]')),
                        ),
                        const SizedBox(height: 14),

                        // Rate
                        _inputField(
                          controller: _rateController,
                          label: 'Annual Interest Rate (%)',
                          icon: LucideIcons.percent,
                          hint: 'e.g. 8.5',
                          context: context,
                          onChanged: (_) => _calculate(),
                          inputType: const TextInputType.numberWithOptions(decimal: true),
                          formatter: FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.]')),
                        ),
                        const SizedBox(height: 14),

                        // Tenure + toggle
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: _inputField(
                                controller: _tenureController,
                                label: 'Tenure',
                                icon: LucideIcons.calendarDays,
                                hint: _tenureInYears ? 'e.g. 5' : 'e.g. 60',
                                context: context,
                                onChanged: (_) => _calculate(),
                                inputType: TextInputType.number,
                                formatter:
                                    FilteringTextInputFormatter.digitsOnly,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                setState(() => _tenureInYears = !_tenureInYears);
                                _calculate();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 13),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  _tenureInYears ? 'Yrs' : 'Mos',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Results card
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                                begin: const Offset(0, 0.1), end: Offset.zero)
                            .animate(animation),
                        child: child,
                      ),
                    ),
                    child: _emi == null
                        ? _emptyResult(secColor)
                        : _resultsCard(isDark, textColor, secColor),
                  ),

                  const SizedBox(height: 20),

                  // Reset button
                  if (_emi != null)
                    TextButton.icon(
                      onPressed: () {
                        _principalController.clear();
                        _rateController.clear();
                        _tenureController.clear();
                        setState(() {
                          _emi = null;
                          _totalInterest = null;
                          _totalPayment = null;
                        });
                      },
                      icon: const Icon(LucideIcons.rotateCcw,
                          size: 16, color: AppTheme.primary),
                      label: const Text('Reset',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  Widget _card(bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgSecondaryDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text, Color color) => Text(
        text,
        style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.3),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required BuildContext context,
    required void Function(String) onChanged,
    required TextInputType inputType,
    required TextInputFormatter formatter,
  }) {
    final secColor = AppTheme.getTextColor(context, isSecondary: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: secColor)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.bgPrimaryDark
                : AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: (isDark ? AppTheme.borderDark : AppTheme.border)
                    .withValues(alpha: 0.5)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: inputType,
            inputFormatters: [formatter],
            onChanged: onChanged,
            style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: secColor.withValues(alpha: 0.4)),
              prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyResult(Color secColor) {
    return Container(
      key: const ValueKey('empty'),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.08), width: 1),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.calculator,
              size: 40, color: AppTheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text('Fill in the details above\nto see your EMI breakdown.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: secColor, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _resultsCard(bool isDark, Color textColor, Color secColor) {
    final principalAmt = double.tryParse(
            _principalController.text.replaceAll(',', '')) ??
        0;
    final interestPercent = _totalPayment! > 0
        ? (_totalInterest! / _totalPayment! * 100).toStringAsFixed(1)
        : '0.0';
    final principalPercent = _totalPayment! > 0
        ? (principalAmt / _totalPayment! * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      key: const ValueKey('results'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          // EMI headline
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryLight,
                  AppTheme.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const Text('Monthly EMI',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(
                  _fmt(_emi!),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5),
                ),
              ],
            ),
          ),

          // Breakdown
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgSecondaryDark : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _resultRow(
                  icon: LucideIcons.indianRupee,
                  label: 'Principal Amount',
                  value: _fmt(principalAmt),
                  color: const Color(0xFF10B981),
                  textColor: textColor,
                  secColor: secColor,
                  pct: '$principalPercent%',
                ),
                const SizedBox(height: 14),
                _resultRow(
                  icon: LucideIcons.trendingUp,
                  label: 'Total Interest',
                  value: _fmt(_totalInterest!),
                  color: const Color(0xFFEF4444),
                  textColor: textColor,
                  secColor: secColor,
                  pct: '$interestPercent%',
                ),
                const SizedBox(height: 14),
                Divider(color: AppTheme.primary.withValues(alpha: 0.1)),
                const SizedBox(height: 10),
                _resultRow(
                  icon: LucideIcons.wallet,
                  label: 'Total Payment',
                  value: _fmt(_totalPayment!),
                  color: AppTheme.primary,
                  textColor: textColor,
                  secColor: secColor,
                  bold: true,
                ),

                const SizedBox(height: 20),

                // Visual bar
                _interestBar(principalAmt),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color textColor,
    required Color secColor,
    String? pct,
    bool bold = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: secColor)),
              if (pct != null)
                Text(pct,
                    style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 16 : 14,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                color: bold ? color : textColor)),
      ],
    );
  }

  Widget _interestBar(double principal) {
    if (_totalPayment == null || _totalPayment! == 0) return const SizedBox();
    final pRatio = (principal / _totalPayment!).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Breakdown',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context, isSecondary: true))),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: LayoutBuilder(builder: (context, constraints) {
              return Row(
                children: [
                  Container(
                    width: constraints.maxWidth * pRatio,
                    color: const Color(0xFF10B981),
                  ),
                  Expanded(child: Container(color: const Color(0xFFEF4444))),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _dot(const Color(0xFF10B981)),
            const SizedBox(width: 4),
            Text('Principal', style: TextStyle(fontSize: 10, color: AppTheme.getTextColor(context, isSecondary: true))),
            const SizedBox(width: 16),
            _dot(const Color(0xFFEF4444)),
            const SizedBox(width: 4),
            Text('Interest', style: TextStyle(fontSize: 10, color: AppTheme.getTextColor(context, isSecondary: true))),
          ],
        ),
      ],
    );
  }

  Widget _dot(Color color) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
