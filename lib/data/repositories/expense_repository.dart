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

  Future<List<Expense>> getExpensesByCategory(
      String monthKey, int? categoryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: categoryId == null
          ? 'month_key = ? AND category_id IS NULL'
          : 'month_key = ? AND category_id = ?',
      whereArgs: categoryId == null ? [monthKey] : [monthKey, categoryId],
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
        SUM(CASE WHEN is_paid = 1 AND planned_amount > 0 THEN planned_amount ELSE 0 END) +
        SUM(CASE WHEN is_paid = 0 AND planned_amount > 0 THEN planned_amount ELSE 0 END) as total_planned,
        SUM(CASE WHEN is_paid = 1 AND planned_amount > 0 THEN planned_amount ELSE 0 END) as confirmed_planned,
        SUM(CASE WHEN is_paid = 0 AND planned_amount > 0 THEN planned_amount ELSE 0 END) as pending_planned,
        SUM(CASE WHEN is_paid = 1 THEN actual_amount ELSE 0 END) as total_actual,
        SUM(CASE WHEN is_paid = 1 AND planned_amount = 0 AND actual_amount > 0 THEN actual_amount ELSE 0 END) as total_unplanned,
        COUNT(CASE WHEN is_paid = 0 AND planned_amount > 0 THEN 1 END) as pending_count
      FROM expenses
      WHERE month_key = ?
    ''', [monthKey]);

    final limit = await getMonthlyLimit(monthKey);

    return {
      'planned': result.first['total_planned'] ?? 0.0,
      'confirmed_planned': result.first['confirmed_planned'] ?? 0.0,
      'pending_planned': result.first['pending_planned'] ?? 0.0,
      'actual': result.first['total_actual'] ?? 0.0,
      'unplanned': result.first['total_unplanned'] ?? 0.0,
      'pending_count': result.first['pending_count'] ?? 0,
      'limit': limit,
    };
  }

  // Get monthly limit from month_plans or users table with carry-over logic
  Future<double> getMonthlyLimit(String monthKey) async {
    final db = await _dbHelper.database;

    // 1. Try to find the most recent limit at or before this month
    final List<Map<String, dynamic>> plans = await db.query(
      'month_plans',
      where: 'month_key <= ? AND total_planned > 0',
      whereArgs: [monthKey],
      orderBy: 'month_key DESC',
      limit: 1,
    );

    if (plans.isNotEmpty) {
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

  /// Sets a budget limit for the given month AND all existing future months
  /// from the current real month onward. Past months are never touched, even
  /// if [fromMonthKey] is in the past (defence-in-depth guard).
  Future<void> updateMonthlyLimitForFuture(
      String fromMonthKey, double limit) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final liveMonthKey = DateTime.now().toIso8601String().substring(0, 7);

    // Update the chosen month itself
    await db.insert(
      'month_plans',
      {
        'month_key': fromMonthKey,
        'total_planned': limit,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update future months that already have a plan entry.
    // Lower bound: must be > fromMonthKey AND >= liveMonthKey
    // so that past months between fromMonthKey and today are never changed.
    final lowerBound =
        fromMonthKey.compareTo(liveMonthKey) >= 0 ? fromMonthKey : liveMonthKey;

    await db.update(
      'month_plans',
      {'total_planned': limit, 'updated_at': now},
      where: 'month_key > ? AND total_planned > 0',
      whereArgs: [lowerBound],
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
        SUM(e.actual_amount) as total_actual,
        MAX(e.created_at) as last_activity
      FROM expenses e
      LEFT JOIN categories c ON e.category_id = c.id
      WHERE e.month_key = ?
      GROUP BY c.id
      HAVING total_planned > 0 OR total_actual > 0
      ORDER BY last_activity DESC
    ''', [monthKey]);

    return result;
  }

  // Get category breakdown for a specific period (last N months)
  Future<List<Map<String, dynamic>>> getCategoryBreakdownForPeriod(
      int months) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months + 1, 1);
    final startMonthKey =
        "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}";

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(c.id, -1) as id,
        COALESCE(c.name, 'General') as category_name,
        COALESCE(c.icon, '📦') as icon,
        COALESCE(c.color, '#808080') as color,
        SUM(COALESCE(e.planned_amount, 0)) as total_planned,
        SUM(COALESCE(e.actual_amount, 0)) as total_actual,
        MAX(e.created_at) as last_activity
      FROM expenses e
      LEFT JOIN categories c ON CAST(e.category_id AS INTEGER) = CAST(c.id AS INTEGER)
      WHERE e.month_key >= ?
      GROUP BY c.id, c.name, c.color, c.icon
      HAVING total_planned > 0 OR total_actual > 0
      ORDER BY total_actual DESC
    ''', [startMonthKey]);

    return result;
  }

  // Get category breakdown for a specific period in days
  Future<List<Map<String, dynamic>>> getCategoryBreakdownForDays(
      int days) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final startDateStr = startDate.toIso8601String().split('T')[0];

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(c.id, -1) as id,
        COALESCE(c.name, 'General') as category_name,
        COALESCE(c.icon, '📦') as icon,
        COALESCE(c.color, '#808080') as color,
        SUM(COALESCE(e.planned_amount, 0)) as total_planned,
        SUM(COALESCE(e.actual_amount, 0)) as total_actual,
        MAX(e.created_at) as last_activity
      FROM expenses e
      LEFT JOIN categories c ON CAST(e.category_id AS INTEGER) = CAST(c.id AS INTEGER)
      WHERE SUBSTR(e.paid_date, 1, 10) >= ? OR (e.paid_date IS NULL AND SUBSTR(e.created_at, 1, 10) >= ?)
      GROUP BY c.id, c.name, c.color, c.icon
      HAVING total_planned > 0 OR total_actual > 0
      ORDER BY total_actual DESC
    ''', [startDateStr, startDateStr]);

    return result;
  }

  // Get spending trends for specified days (only paid/debit transactions)
  Future<List<Map<String, dynamic>>> getDailyTrends(int days) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final startDateStr = startDate.toIso8601String().split('T')[0];

    final result = await db.rawQuery('''
      SELECT 
        SUBSTR(paid_date, 1, 10) as date_key,
        SUM(CASE WHEN planned_amount > 0 THEN planned_amount ELSE 0 END) as total_planned,
        SUM(actual_amount) as total_actual
      FROM expenses
      WHERE is_paid = 1
        AND paid_date IS NOT NULL
        AND SUBSTR(paid_date, 1, 10) >= ?
      GROUP BY date_key
      ORDER BY date_key ASC
    ''', [startDateStr]);

    return result;
  }

  // Get spending trends for specified months (calendar-aligned, only paid/debit transactions)
  Future<List<Map<String, dynamic>>> getTrends(int months) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    // Calculate start month key (e.g., if now is 2026-02 and months is 6, start is 2025-09)
    final startDate = DateTime(now.year, now.month - months + 1, 1);
    final startMonthKey =
        "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}";

    final result = await db.rawQuery('''
      SELECT 
        month_key,
        SUM(CASE WHEN planned_amount > 0 THEN planned_amount ELSE 0 END) as total_planned,
        SUM(CASE WHEN is_paid = 1 THEN actual_amount ELSE 0 END) as total_actual
      FROM expenses
      WHERE month_key >= ?
      GROUP BY month_key
      ORDER BY month_key ASC
    ''', [startMonthKey]);

    return result;
  }

  // Get Analytics summary for a specific calendar period
  Future<Map<String, double>> getAnalyticsSummary(int months) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months + 1, 1);
    final startMonthKey =
        "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}";

    // Get average and max from grouped month data within the period
    final result = await db.rawQuery('''
      SELECT 
        SUM(actual_total) as sum_actual,
        MAX(actual_total) as max_actual,
        SUM(planned_total) as sum_planned,
        MAX(planned_total) as max_planned
      FROM (
        SELECT 
          SUM(actual_amount) as actual_total,
          SUM(planned_amount) as planned_total
        FROM expenses
        WHERE month_key >= ?
        GROUP BY month_key
      )
    ''', [startMonthKey]);

    if (result.isEmpty || result.first['sum_actual'] == null) {
      return {'avg_spent': 0.0, 'max_spent': 0.0};
    }

    // Calculation logic:
    // Average = Total Sum / Period Months (to account for months with 0 spending)
    final sumActual = (result.first['sum_actual'] as num).toDouble();
    final maxActual = (result.first['max_actual'] as num).toDouble();
    final sumPlanned = (result.first['sum_planned'] as num).toDouble();
    final maxPlanned = (result.first['max_planned'] as num).toDouble();

    final avgActual = sumActual / months;
    final avgPlanned = sumPlanned / months;

    return {
      'avg_spent': avgActual > 0 ? avgActual : avgPlanned,
      'max_spent': maxActual > 0 ? maxActual : maxPlanned,
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

  // Delete imported expenses for a specific month
  Future<int> deleteImportedExpenses(String monthKey) async {
    final db = await _dbHelper.database;
    final result = await db.delete(
      'expenses',
      where: "month_key = ? AND notes LIKE 'SMS_ID:%'",
      whereArgs: [monthKey],
    );
    return result;
  }

  // Get list of imported SMS IDs (correctly extracts just the SMS ID portion from notes)
  Future<List<String>> getImportedSmsIds() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'expenses',
      columns: ['notes'],
      where: "notes LIKE 'SMS_ID:%'",
    );
    return result.map((e) {
      final notes = e['notes'] as String;
      // Notes format: 'SMS_ID:{id} | MSG:{raw}'
      // We need to extract only the ID portion before ' | '
      final smsIdPart = notes.replaceFirst('SMS_ID:', '');
      final separatorIdx = smsIdPart.indexOf(' | ');
      return separatorIdx >= 0
          ? smsIdPart.substring(0, separatorIdx)
          : smsIdPart;
    }).toList();
  }
}
