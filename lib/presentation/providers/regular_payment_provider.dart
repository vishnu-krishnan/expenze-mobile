import 'package:flutter/material.dart';
import '../../data/services/database_helper.dart';

class RegularPayment {
  final int? id;
  final String name;
  final int categoryId;
  final String? categoryName;
  final double defaultPlannedAmount;
  final String? notes;
  final String startDate;
  final String? endDate;
  final String frequency;
  final int? durationMonths; // New field for period in months
  final bool isActive;
  final String? status;
  final String? statusDescription;

  RegularPayment({
    this.id,
    required this.name,
    required this.categoryId,
    this.categoryName,
    required this.defaultPlannedAmount,
    this.notes,
    required this.startDate,
    this.endDate,
    required this.frequency,
    this.durationMonths,
    required this.isActive,
    this.status,
    this.statusDescription,
  });

  factory RegularPayment.fromMap(Map<String, dynamic> map) {
    return RegularPayment(
      id: map['id'],
      name: map['name'] ?? '',
      categoryId: map['category_id'] ?? 0,
      categoryName: map['categoryName'],
      defaultPlannedAmount:
          (map['default_planned_amount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
      startDate: map['start_date'] ?? '',
      endDate: map['end_date'],
      frequency: map['frequency'] ?? 'MONTHLY',
      durationMonths: map['duration_months'],
      isActive: map['is_active'] == 1,
      status: map['status'],
      statusDescription: map['status_description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'default_planned_amount': defaultPlannedAmount,
      'notes': notes,
      'start_date': startDate,
      'end_date': endDate,
      'frequency': frequency,
      'duration_months': durationMonths,
      'is_active': isActive ? 1 : 0,
      'status': status,
      'status_description': statusDescription,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  RegularPayment copyWith({
    int? id,
    String? name,
    int? categoryId,
    String? categoryName,
    double? defaultPlannedAmount,
    String? notes,
    String? startDate,
    String? endDate,
    String? frequency,
    int? durationMonths,
    bool? isActive,
    String? status,
    String? statusDescription,
  }) {
    return RegularPayment(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      defaultPlannedAmount: defaultPlannedAmount ?? this.defaultPlannedAmount,
      notes: notes ?? this.notes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      frequency: frequency ?? this.frequency,
      durationMonths: durationMonths ?? this.durationMonths,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      statusDescription: statusDescription ?? this.statusDescription,
    );
  }
}

class RegularPaymentProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<RegularPayment> _payments = [];
  bool _isLoading = false;

  RegularPaymentProvider();

  List<RegularPayment> get payments => _payments;
  bool get isLoading => _isLoading;

  Future<void> loadPayments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT rp.*, c.name as categoryName 
        FROM regular_payments rp
        LEFT JOIN categories c ON rp.category_id = c.id
      ''');
      _payments = maps.map((m) => RegularPayment.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error loading regular payments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPayment(RegularPayment payment) async {
    final db = await _dbHelper.database;
    await db.insert('regular_payments', payment.toMap());
    await loadPayments();
  }

  Future<void> updatePayment(RegularPayment payment) async {
    if (payment.id == null) return;
    final db = await _dbHelper.database;
    await db.update('regular_payments', payment.toMap(),
        where: 'id = ?', whereArgs: [payment.id]);
    await loadPayments();
  }

  Future<void> deletePayment(int id) async {
    final db = await _dbHelper.database;
    await db.delete('regular_payments', where: 'id = ?', whereArgs: [id]);
    await loadPayments();
  }
}
