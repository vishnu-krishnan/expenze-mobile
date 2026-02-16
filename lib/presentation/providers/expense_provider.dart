import 'package:flutter/material.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();

  ExpenseProvider();

  List<Expense> _expenses = [];
  Map<String, double> _summary = {'planned': 0, 'actual': 0, 'remaining': 0};
  bool _isLoading = false;
  String _currentMonthKey = DateTime.now().toIso8601String().substring(0, 7);
  List<Map<String, dynamic>> _trends = [];
  List<Map<String, dynamic>> _categoryBreakdown = [];
  double _avgMonthlySpent = 0;
  double _maxMonthlySpent = 0;

  List<Expense> get expenses => _expenses;
  Map<String, double> get summary => _summary;
  bool get isLoading => _isLoading;
  String get currentMonthKey => _currentMonthKey;
  List<Map<String, dynamic>> get trends => _trends;
  List<Map<String, dynamic>> get categoryBreakdown => _categoryBreakdown;
  double get avgMonthlySpent => _avgMonthlySpent;
  double get maxMonthlySpent => _maxMonthlySpent;

  void setMonth(String monthKey) {
    _currentMonthKey = monthKey;
    loadMonthData(monthKey);
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
      _categoryBreakdown = await _repository.getCategoryBreakdown(monthKey);

      _summary = {
        'planned': (rawSummary['planned'] as num).toDouble(),
        'actual': (rawSummary['actual'] as num).toDouble(),
        'remaining':
            ((rawSummary['planned'] as num) - (rawSummary['actual'] as num))
                .toDouble(),
      };
    } catch (e) {
      print('Error loading expenses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTrends(int months) async {
    _isLoading = true;
    notifyListeners();
    try {
      _trends = await _repository.getTrends(months);
      final summary = await _repository.getAnalyticsSummary(months);
      _avgMonthlySpent = summary['avg_spent'] ?? 0;
      _maxMonthlySpent = summary['max_spent'] ?? 0;
    } catch (e) {
      print('Error loading trends: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    await _repository.insertExpense(expense);
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

  Future<void> togglePaid(Expense expense, double actualAmount) async {
    final updated = expense.copyWith(
      isPaid: !expense.isPaid,
      actualAmount: !expense.isPaid ? actualAmount : 0,
    );
    await updateExpense(updated);
  }

  double get totalPlanned =>
      _expenses.fold(0, (sum, e) => sum + e.plannedAmount);
  double get totalActual => _expenses.fold(0, (sum, e) => sum + e.actualAmount);
}
