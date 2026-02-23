import 'package:flutter/material.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';
import 'package:intl/intl.dart';
import '../../core/utils/logger.dart';

enum SortOption { recent, amountAsc, amountDesc }

class ExpenseProvider with ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();

  ExpenseProvider();

  List<Expense> _expenses = [];
  Map<String, double> _summary = {
    'planned': 0,
    'actual': 0,
    'remaining': 0,
    'limit': 0
  };
  bool _isLoading = false;
  static String get _liveMonthKey =>
      DateTime.now().toIso8601String().substring(0, 7);

  String _currentMonthKey = DateTime.now().toIso8601String().substring(0, 7);
  List<Map<String, dynamic>> _trends = [];
  List<Map<String, dynamic>> _categoryBreakdown = [];
  SortOption _currentSortOption = SortOption.recent;
  double _avgMonthlySpent = 0;
  double _maxMonthlySpent = 0;

  List<Expense> get expenses => _expenses;
  Map<String, double> get summary => _summary;
  bool get isLoading => _isLoading;
  String get currentMonthKey => _currentMonthKey;
  List<Map<String, dynamic>> get trends => _trends;
  List<Map<String, dynamic>> get categoryBreakdown => _categoryBreakdown;
  SortOption get currentSortOption => _currentSortOption;
  double get avgMonthlySpent => _avgMonthlySpent;
  double get maxMonthlySpent => _maxMonthlySpent;

  void setMonth(String monthKey) {
    _currentMonthKey = monthKey;
    loadMonthData(monthKey);
  }

  /// Resets the selected month to today's month and reloads data.
  /// Called whenever the user navigates to a new tab or pulls to refresh.
  Future<void> resetToCurrentMonth() async {
    final key = _liveMonthKey;
    if (_currentMonthKey != key || _expenses.isEmpty) {
      await loadMonthData(key);
    }
  }

  Future<void> loadMonthData(String monthKey) async {
    _currentMonthKey = monthKey;
    _isLoading = true;
    notifyListeners();

    try {
      // Auto-sync regular payments first
      await _repository.syncRegularPayments(monthKey);

      _expenses = await _repository.getExpensesByMonth(monthKey);
      final rawSummary = await _repository.getMonthSummary(monthKey);
      _categoryBreakdown = List<Map<String, dynamic>>.from(
          await _repository.getCategoryBreakdown(monthKey));

      final actual = (rawSummary['actual'] as num).toDouble();
      final planned = (rawSummary['planned'] as num).toDouble();
      final confirmedPlanned =
          (rawSummary['confirmed_planned'] as num?)?.toDouble() ?? 0.0;
      final pendingPlanned =
          (rawSummary['pending_planned'] as num?)?.toDouble() ?? 0.0;
      final unplanned = (rawSummary['unplanned'] as num?)?.toDouble() ?? 0.0;

      final limit = (rawSummary['limit'] as num).toDouble();

      // If limit is set (>0), use it for remaining calculation, otherwise use planned sum
      final targetAmount = limit > 0 ? limit : planned;

      _summary = {
        'planned': planned,
        'confirmed_planned': confirmedPlanned,
        'pending_planned': pendingPlanned,
        'actual': actual,
        'unplanned': unplanned,
        'limit': limit,
        'remaining': (targetAmount - actual).toDouble(),
      };

      applySort();
    } catch (e) {
      logger.e('Error loading expenses', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _periodCategoryBreakdown = [];
  List<Map<String, dynamic>> get periodCategoryBreakdown =>
      _periodCategoryBreakdown;

  double _periodTotalSpent = 0;
  double get periodTotalSpent => _periodTotalSpent;

  Future<void> loadTrends(int value, {bool isDays = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      List<Map<String, dynamic>> rawTrends;
      List<Map<String, dynamic>> rawBreakdown;
      final List<Map<String, dynamic>> filledTrends = [];
      final now = DateTime.now();

      if (isDays) {
        rawTrends = await _repository.getDailyTrends(value);
        rawBreakdown = await _repository.getCategoryBreakdownForDays(value);

        for (int i = value - 1; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final key = DateFormat('yyyy-MM-dd').format(date);
          final existing = rawTrends.firstWhere(
            (e) => e['date_key'] == key,
            orElse: () => {},
          );
          filledTrends.add({
            'month_key': key, // Keep key name for chart compatibility
            'total_planned': existing.isNotEmpty
                ? (existing['total_planned'] as num).toDouble()
                : 0.0,
            'total_actual': existing.isNotEmpty
                ? (existing['total_actual'] as num).toDouble()
                : 0.0,
          });
        }
        _trends = filledTrends;
      } else {
        rawTrends = await _repository.getTrends(value);
        rawBreakdown = await _repository.getCategoryBreakdownForPeriod(value);

        for (int i = value - 1; i >= 0; i--) {
          final date = DateTime(now.year, now.month - i, 1);
          final key = DateFormat('yyyy-MM').format(date);
          final existing = rawTrends.firstWhere(
            (e) => e['month_key'] == key,
            orElse: () => {},
          );
          filledTrends.add({
            'month_key': key,
            'total_planned': existing.isNotEmpty
                ? (existing['total_planned'] as num).toDouble()
                : 0.0,
            'total_actual': existing.isNotEmpty
                ? (existing['total_actual'] as num).toDouble()
                : 0.0,
          });
        }

        if (value == 60) {
          final Map<String, Map<String, dynamic>> yearlyAggregation = {};
          for (var m in filledTrends) {
            final year = m['month_key'].split('-')[0];
            if (!yearlyAggregation.containsKey(year)) {
              yearlyAggregation[year] = {
                'month_key': '$year-01',
                'total_planned': 0.0,
                'total_actual': 0.0,
              };
            }
            yearlyAggregation[year]!['total_planned'] += m['total_planned'];
            yearlyAggregation[year]!['total_actual'] += m['total_actual'];
          }
          _trends = yearlyAggregation.values.toList()
            ..sort((a, b) => a['month_key'].compareTo(b['month_key']));
        } else {
          _trends = filledTrends;
        }
      }

      _periodCategoryBreakdown = List<Map<String, dynamic>>.from(rawBreakdown);

      // Compute period-accurate summary stats directly from the filled trends
      final nonZero = _trends
          .where((e) => (e['total_actual'] as num).toDouble() > 0)
          .toList();
      _periodTotalSpent = _trends.fold(
          0.0, (s, e) => s + (e['total_actual'] as num).toDouble());
      _avgMonthlySpent =
          nonZero.isEmpty ? 0 : _periodTotalSpent / nonZero.length;
      _maxMonthlySpent = nonZero.isEmpty
          ? 0
          : nonZero
              .map((e) => (e['total_actual'] as num).toDouble())
              .reduce((a, b) => a > b ? a : b);
    } catch (e) {
      logger.e('Error loading trends', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    await _repository.insertExpense(expense);
    await loadMonthData(_currentMonthKey);
  }

  Future<void> addExpenses(List<Expense> expenses) async {
    if (expenses.isEmpty) return;
    for (var expense in expenses) {
      await _repository.insertExpense(expense);
    }
    await loadMonthData(_currentMonthKey);
  }

  Future<void> updateExpense(Expense expense) async {
    await _repository.updateExpense(expense);
    await loadMonthData(_currentMonthKey);
  }

  Future<void> deleteExpense(int id) async {
    await _repository.deleteExpense(id);
    await loadMonthData(_currentMonthKey);
  }

  Future<void> updateMonthlyLimit(double limit) async {
    await _repository.updateMonthlyLimit(_currentMonthKey, limit);
    await loadMonthData(_currentMonthKey);
  }

  /// Sets the budget limit for ONLY the currently viewed month.
  Future<void> updateMonthlyLimitThisMonthOnly(double limit) async {
    await _repository.updateMonthlyLimit(_currentMonthKey, limit);
    await loadMonthData(_currentMonthKey);
  }

  /// Sets the budget limit for the currently viewed month AND all future months.
  /// Past months remain unchanged.
  Future<void> updateMonthlyLimitFuture(double limit) async {
    await _repository.updateMonthlyLimitForFuture(_currentMonthKey, limit);
    await loadMonthData(_currentMonthKey);
  }

  Future<void> togglePaid(Expense expense, double actualAmount,
      {String? paidDate}) async {
    final updated = expense.copyWith(
      isPaid: !expense.isPaid,
      actualAmount: !expense.isPaid ? actualAmount : 0,
      paidDate: !expense.isPaid
          ? (paidDate ?? DateTime.now().toIso8601String())
          : null,
    );
    await updateExpense(updated);
  }

  double get totalPlanned =>
      _expenses.fold(0, (sum, e) => sum + e.plannedAmount);

  double get totalActual => _expenses.fold(0, (sum, e) => sum + e.actualAmount);

  Future<List<String>> getImportedSmsIds() => _repository.getImportedSmsIds();

  void setSortOption(SortOption option) {
    if (_currentSortOption == option) return;
    _currentSortOption = option;
    applySort();
    notifyListeners();
  }

  void applySort() {
    if (_categoryBreakdown.isEmpty) return;

    final sortedList = List<Map<String, dynamic>>.from(_categoryBreakdown);
    sortedList.sort((a, b) {
      if (_currentSortOption == SortOption.recent) {
        final aDate = a['last_activity'] as String?;
        final bDate = b['last_activity'] as String?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate); // Descending
      }

      final aActual = (a['total_actual'] as num?)?.toDouble() ?? 0.0;
      final bActual = (b['total_actual'] as num?)?.toDouble() ?? 0.0;
      final aPlanned = (a['total_planned'] as num?)?.toDouble() ?? 0.0;
      final bPlanned = (b['total_planned'] as num?)?.toDouble() ?? 0.0;

      final aVal = aActual > 0 ? aActual : aPlanned;
      final bVal = bActual > 0 ? bActual : bPlanned;

      if (_currentSortOption == SortOption.amountAsc) {
        return aVal.compareTo(bVal);
      } else {
        return bVal.compareTo(aVal);
      }
    });

    _categoryBreakdown = sortedList;
  }

  Future<void> clearImportedExpenses(String monthKey) async {
    await _repository.deleteImportedExpenses(monthKey);
    await loadMonthData(monthKey);
  }
}
