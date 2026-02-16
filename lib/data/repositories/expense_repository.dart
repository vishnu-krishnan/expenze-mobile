import 'package:sqflite/sqflite.dart';
import '../services/database_helper.dart';
import '../models/expense.dart';

class ExpenseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get all expenses for a month
  Future<List<Expense>> getExpensesByMonth(String monthKey) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'month_key = ?',
      whereArgs: [monthKey],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  // Get expense by ID
  Future<Expense?> getExpenseById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Expense.fromMap(maps.first);
  }

  // Insert expense
  Future<int> insertExpense(Expense expense) async {
    final db = await _dbHelper.database;
    final id = await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Add to sync queue
    await _addToSyncQueue('expenses', id, 'INSERT', expense.toMap());

    return id;
  }

  // Update expense
  Future<int> updateExpense(Expense expense) async {
    final db = await _dbHelper.database;
    final result = await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );

    // Add to sync queue
    await _addToSyncQueue('expenses', expense.id!, 'UPDATE', expense.toMap());

    return result;
  }

  // Delete expense
  Future<int> deleteExpense(int id) async {
    final db = await _dbHelper.database;
    final result = await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Add to sync queue
    await _addToSyncQueue('expenses', id, 'DELETE', {});

    return result;
  }

  // Get month summary
  Future<Map<String, dynamic>> getMonthSummary(String monthKey) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT 
        SUM(planned_amount) as total_planned,
        SUM(actual_amount) as total_actual,
        COUNT(CASE WHEN is_paid = 0 THEN 1 END) as pending_count
      FROM expenses
      WHERE month_key = ?
    ''', [monthKey]);

    final limit = await getMonthlyLimit(monthKey);

    return {
      'planned': result.first['total_planned'] ?? 0.0,
      'actual': result.first['total_actual'] ?? 0.0,
      'pending_count': result.first['pending_count'] ?? 0,
      'limit': limit,
    };
  }

  // Get monthly limit from month_plans or users table
  Future<double> getMonthlyLimit(String monthKey) async {
    final db = await _dbHelper.database;

    // 1. Try month_plans first
    final List<Map<String, dynamic>> plans = await db.query(
      'month_plans',
      where: 'month_key = ?',
      whereArgs: [monthKey],
      limit: 1,
    );

    if (plans.isNotEmpty && (plans.first['total_planned'] as num) > 0) {
      return (plans.first['total_planned'] as num).toDouble();
    }

    // 2. Fallback to user's default_budget
    final List<Map<String, dynamic>> users = await db.query('users', limit: 1);
    if (users.isNotEmpty) {
      return (users.first['default_budget'] as num?)?.toDouble() ?? 0.0;
    }

    return 0.0;
  }

  // Update monthly limit in month_plans table
  Future<void> updateMonthlyLimit(String monthKey, double limit) async {
    final db = await _dbHelper.database;
    await db.insert(
      'month_plans',
      {
        'month_key': monthKey,
        'total_planned': limit,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get category breakdown for a month
  Future<List<Map<String, dynamic>>> getCategoryBreakdown(
      String monthKey) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT 
        c.id,
        c.name as category_name,
        c.icon,
        c.color,
        SUM(e.planned_amount) as total_planned,
        SUM(e.actual_amount) as total_actual
      FROM expenses e
      LEFT JOIN categories c ON e.category_id = c.id
      WHERE e.month_key = ?
      GROUP BY c.id
      HAVING total_planned > 0 OR total_actual > 0
      ORDER BY total_actual DESC, total_planned DESC
    ''', [monthKey]);

    return result;
  }

  // Get spending trends for specified months
  Future<List<Map<String, dynamic>>> getTrends(int months) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT 
        month_key,
        SUM(planned_amount) as total_planned,
        SUM(actual_amount) as total_actual
      FROM expenses
      GROUP BY month_key
      ORDER BY month_key ASC
    ''');

    // Take only the last N months record to show recent trends
    if (result.length > months) {
      return result.sublist(result.length - months);
    }

    return result;
  }

  // Get Analytics summary for a period
  Future<Map<String, double>> getAnalyticsSummary(int months) async {
    final db = await _dbHelper.database;

    // Get average and max from grouped month data
    final result = await db.rawQuery('''
      SELECT 
        AVG(actual_total) as avg_spent,
        MAX(actual_total) as max_spent,
        AVG(planned_total) as avg_planned,
        MAX(planned_total) as max_planned
      FROM (
        SELECT 
          SUM(actual_amount) as actual_total,
          SUM(planned_amount) as planned_total
        FROM expenses
        GROUP BY month_key
        ORDER BY month_key DESC
        LIMIT ?
      )
    ''', [months]);

    if (result.isEmpty || result.first['avg_spent'] == null) {
      return {'avg_spent': 0.0, 'max_spent': 0.0};
    }

    final avgSpent = (result.first['avg_spent'] as num).toDouble();
    final maxSpent = (result.first['max_spent'] as num).toDouble();
    final avgPlanned = (result.first['avg_planned'] as num).toDouble();
    final maxPlanned = (result.first['max_planned'] as num).toDouble();

    return {
      'avg_spent': avgSpent > 0 ? avgSpent : avgPlanned,
      'max_spent': maxSpent > 0 ? maxSpent : maxPlanned,
    };
  }

  // Mark expense as paid
  Future<int> markAsPaid(int id, double actualAmount) async {
    final db = await _dbHelper.database;
    final result = await db.update(
      'expenses',
      {
        'is_paid': 1,
        'actual_amount': actualAmount,
        'paid_date': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    // Add to sync queue
    await _addToSyncQueue('expenses', id, 'UPDATE', {
      'is_paid': 1,
      'actual_amount': actualAmount,
      'paid_date': DateTime.now().toIso8601String(),
    });

    return result;
  }

  // Add to sync queue
  Future<void> _addToSyncQueue(
    String tableName,
    int recordId,
    String action,
    Map<String, dynamic> data,
  ) async {
    final db = await _dbHelper.database;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'action': action,
      'data': data.toString(), // In production, use json.encode
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  // Sync regular payments to a specific month
  Future<void> syncRegularPayments(String monthKey) async {
    final db = await _dbHelper.database;

    // 1. Get all active regular payments
    final List<Map<String, dynamic>> recurring = await db.query(
      'regular_payments',
      where: 'is_active = ?',
      whereArgs: [1],
    );

    for (var rp in recurring) {
      // 2. Check if already exists in expenses for this month
      final List<Map<String, dynamic>> existing = await db.query(
        'expenses',
        where: 'month_key = ? AND name = ? AND category_id = ?',
        whereArgs: [monthKey, rp['name'], rp['category_id']],
      );

      if (existing.isEmpty) {
        // 3. Create expense entry
        final now = DateTime.now().toIso8601String();
        await db.insert('expenses', {
          'month_key': monthKey,
          'category_id': rp['category_id'],
          'name': rp['name'],
          'planned_amount': rp['default_planned_amount'],
          'actual_amount': 0.0,
          'is_paid': 0,
          'notes': rp['notes'],
          'priority': 'MEDIUM',
          'synced': 0,
          'created_at': now,
          'updated_at': now,
        });
      }
    }
  }

  // Get unsynced changes
  Future<List<Map<String, dynamic>>> getUnsyncedChanges() async {
    final db = await _dbHelper.database;
    return await db.query(
      'sync_queue',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );
  }

  // Mark as synced
  Future<void> markAsSynced(int syncQueueId) async {
    final db = await _dbHelper.database;
    await db.update(
      'sync_queue',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [syncQueueId],
    );
  }
}
