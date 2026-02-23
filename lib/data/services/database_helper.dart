import 'package:sqflite/sqflite.dart';
import '../../core/utils/logger.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenze.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 18,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE regular_payments ADD COLUMN notes TEXT');
        await db
            .execute('ALTER TABLE regular_payments ADD COLUMN start_date TEXT');
        await db
            .execute('ALTER TABLE regular_payments ADD COLUMN end_date TEXT');
        await db
            .execute('ALTER TABLE regular_payments ADD COLUMN frequency TEXT');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN password TEXT');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN full_name TEXT');
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
      } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute(
            "ALTER TABLE expenses ADD COLUMN priority TEXT DEFAULT 'MEDIUM'");
      } catch (_) {}
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          content TEXT,
          reminder_date TEXT,
          is_reminder_active INTEGER DEFAULT 0,
          is_pinned INTEGER DEFAULT 0,
          color TEXT,
          created_at TEXT,
          updated_at TEXT
        )
      ''');
    }
    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE regular_payments ADD COLUMN status TEXT');
        await db.execute(
            'ALTER TABLE regular_payments ADD COLUMN status_description TEXT');
      } catch (_) {}
    }
    if (oldVersion < 9 || oldVersion < 10) {
      try {
        await db.execute(
            'ALTER TABLE regular_payments ADD COLUMN duration_months INTEGER');
      } catch (_) {}
    }
    if (oldVersion < 11) {
      await _insertDefaultCategories(db);
    }
    if (oldVersion < 12 || oldVersion < 13) {
      try {
        await db.execute(
            "ALTER TABLE expenses ADD COLUMN payment_mode TEXT DEFAULT 'Other'");
      } catch (_) {}
    }
    if (oldVersion < 15) {
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(users)');
        final hasEmail = tableInfo.any((col) => col['name'] == 'email');
        if (!hasEmail) {
          await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
        }

        final hasUsername = tableInfo.any((col) => col['name'] == 'username');
        if (hasUsername) {
          await db.execute(
              "UPDATE users SET email = username WHERE (email IS NULL OR email = '') AND username IS NOT NULL");
        }
      } catch (e) {
        logger.e("Database migration error (v15)", error: e);
      }
    }
    if (oldVersion < 16) {
      try {
        final regPaymentsInfo =
            await db.rawQuery('PRAGMA table_info(regular_payments)');
        final hasPriority =
            regPaymentsInfo.any((col) => col['name'] == 'priority');
        if (!hasPriority) {
          await db.execute(
              "ALTER TABLE regular_payments ADD COLUMN priority TEXT DEFAULT 'MEDIUM'");
        }

        final expenseInfo = await db.rawQuery('PRAGMA table_info(expenses)');
        final hasExpPriority =
            expenseInfo.any((col) => col['name'] == 'priority');
        if (!hasExpPriority) {
          await db.execute(
              "ALTER TABLE expenses ADD COLUMN priority TEXT DEFAULT 'MEDIUM'");
        }
      } catch (e) {
        logger.e("Database migration error (v16)", error: e);
      }
    }
    if (oldVersion < 17) {
      try {
        final regPaymentsInfo =
            await db.rawQuery('PRAGMA table_info(regular_payments)');
        final hasPriority =
            regPaymentsInfo.any((col) => col['name'] == 'priority');
        if (!hasPriority) {
          await db.execute(
              "ALTER TABLE regular_payments ADD COLUMN priority TEXT DEFAULT 'MEDIUM'");
        }

        final expenseInfo = await db.rawQuery('PRAGMA table_info(expenses)');
        final hasExpPriority =
            expenseInfo.any((col) => col['name'] == 'priority');
        if (!hasExpPriority) {
          await db.execute(
              "ALTER TABLE expenses ADD COLUMN priority TEXT DEFAULT 'MEDIUM'");
        }
      } catch (e) {
        logger.e("Database migration error (v17)", error: e);
      }
    }
    if (oldVersion < 18) {
      try {
        final userInfo = await db.rawQuery('PRAGMA table_info(users)');

        if (!userInfo.any((col) => col['name'] == 'default_budget')) {
          await db.execute(
              'ALTER TABLE users ADD COLUMN default_budget REAL DEFAULT 0');
        }
        if (!userInfo.any((col) => col['name'] == 'synced')) {
          await db
              .execute('ALTER TABLE users ADD COLUMN synced INTEGER DEFAULT 0');
        }
        if (!userInfo.any((col) => col['name'] == 'created_at')) {
          await db.execute('ALTER TABLE users ADD COLUMN created_at TEXT');
        }
        if (!userInfo.any((col) => col['name'] == 'updated_at')) {
          await db.execute('ALTER TABLE users ADD COLUMN updated_at TEXT');
        }
      } catch (e) {
        logger.e("Database migration error (v18)", error: e);
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        full_name TEXT,
        phone TEXT,
        password TEXT,
        default_budget REAL DEFAULT 0,
        synced INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        synced INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Month plans table
    await db.execute('''
      CREATE TABLE month_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month_key TEXT NOT NULL,
        total_planned REAL DEFAULT 0,
        total_actual REAL DEFAULT 0,
        synced INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        UNIQUE(month_key)
      )
    ''');

    // Expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month_key TEXT NOT NULL,
        category_id INTEGER,
        name TEXT NOT NULL,
        planned_amount REAL DEFAULT 0,
        actual_amount REAL DEFAULT 0,
        is_paid INTEGER DEFAULT 0,
        due_date TEXT,
        paid_date TEXT,
        payment_mode TEXT DEFAULT 'Other',
        notes TEXT,
        priority TEXT DEFAULT 'MEDIUM',
        synced INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Regular payments/templates table
    await db.execute('''
      CREATE TABLE regular_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category_id INTEGER,
        default_planned_amount REAL DEFAULT 0,
        notes TEXT,
        start_date TEXT,
        end_date TEXT,
        frequency TEXT,
        is_active INTEGER DEFAULT 1,
        status TEXT,
        status_description TEXT,
        duration_months INTEGER,
        priority TEXT DEFAULT 'MEDIUM',
        synced INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // SMS messages table
    await db.execute('''
      CREATE TABLE sms_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender TEXT,
        message TEXT,
        timestamp TEXT,
        amount REAL,
        transaction_type TEXT,
        merchant TEXT,
        processed INTEGER DEFAULT 0,
        expense_id INTEGER,
        created_at TEXT,
        FOREIGN KEY (expense_id) REFERENCES expenses (id)
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        data TEXT,
        created_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT,
        reminder_date TEXT,
        is_reminder_active INTEGER DEFAULT 0,
        is_pinned INTEGER DEFAULT 0,
        color TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Finalize DB creation
    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final categories = [
      {'name': 'Food & Dining', 'icon': '🍕', 'color': '#FF6B6B'},
      {'name': 'Transportation', 'icon': '🚗', 'color': '#4D96FF'},
      {'name': 'Shopping', 'icon': '🛍️', 'color': '#FFD93D'},
      {'name': 'Bills & Utilities', 'icon': '💡', 'color': '#6BCB77'},
      {'name': 'Entertainment', 'icon': '🎬', 'color': '#A66CFF'},
      {'name': 'Healthcare', 'icon': '🏥', 'color': '#FF87CA'},
      {'name': 'Recharge', 'icon': '📱', 'color': '#4FC3F7'},
      {'name': 'Petrol/Fuel', 'icon': '⛽', 'color': '#FF9F43'},
      {'name': 'Travel', 'icon': '✈️', 'color': '#00D2FC'},
      {'name': 'Education', 'icon': '📚', 'color': '#9B51E0'},
      {'name': 'Groceries', 'icon': '🛒', 'color': '#27AE60'},
      {'name': 'Investment', 'icon': '📈', 'color': '#2D9CDB'},
      {'name': 'Rent', 'icon': '🏠', 'color': '#F2994A'},
      {'name': 'Loan', 'icon': '📜', 'color': '#EB5757'},
      {'name': 'EMI', 'icon': '💳', 'color': '#56CCF2'},
      {'name': 'Subscriptions', 'icon': '📺', 'color': '#BB6BD9'},
      {'name': 'Fitness', 'icon': '💪', 'color': '#F2C94C'},
      {'name': 'Gifts', 'icon': '🎁', 'color': '#FF4D81'},
      {'name': 'Other', 'icon': '📦', 'color': '#BDBDBD'},
    ];

    for (var cat in categories) {
      // Check if category already exists by name to avoid duplicates during upgrade
      final List<Map<String, dynamic>> existing = await db.query(
        'categories',
        where: 'name = ?',
        whereArgs: [cat['name']],
      );

      if (existing.isEmpty) {
        await db.insert('categories', {
          ...cat,
          'synced': 0,
          'created_at': now,
        });
      }
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('users');
    await db.delete('expenses');
    await db.delete('month_plans');
    await db.delete('regular_payments');
    await db.delete('sms_messages');
    await db.delete('sync_queue');
    await db.delete('notes');
  }

  // Auth related
  Future<Map<String, dynamic>?> getUser(String email) async {
    final db = await instance.database;
    final res = await db.query('users',
        where: 'email = ?', whereArgs: [email], limit: 1);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> registerUser({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final db = await instance.database;
    return await db.insert('users', {
      'email': email,
      'password': password,
      'full_name': fullName,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> upsertUser({
    required String email,
    String? fullName,
    double? defaultBudget,
  }) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();

    Map<String, dynamic>? existing;
    if (email.isNotEmpty) {
      final res = await db.query('users',
          where: 'email = ?', whereArgs: [email], limit: 1);
      if (res.isNotEmpty) existing = res.first;
    }

    final data = <String, dynamic>{
      'email': email,
      'full_name': fullName ?? existing?['full_name'],
      'default_budget': defaultBudget ?? (existing?['default_budget'] ?? 0.0),
      'updated_at': now,
      'synced': 0,
    };

    if (existing != null) {
      await db
          .update('users', data, where: 'id = ?', whereArgs: [existing['id']]);
      return existing['id'] as int;
    } else {
      data['created_at'] = now;
      return await db.insert('users', data);
    }
  }

  Future<void> updateUserProfile(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.update(
        'users',
        {
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<void> updatePassword(String email, String newPassword) async {
    final db = await instance.database;
    await db.update(
      'users',
      {'password': newPassword, 'updated_at': DateTime.now().toIso8601String()},
      where: 'email = ?',
      whereArgs: [email],
    );
  }
}
