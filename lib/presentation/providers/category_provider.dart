import 'package:flutter/material.dart';
import '../../data/services/database_helper.dart';
import '../../data/models/category.dart';
import '../../core/utils/logger.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Category> _categories = [];
  bool _isLoading = false;

  CategoryProvider();

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps =
          await db.query('categories', orderBy: 'name ASC');
      final all = maps.map((m) => Category.fromMap(m)).toList();

      // Deduplicate by name (case-insensitive) — keeps the first occurrence
      final seen = <String>{};
      _categories = all.where((c) => seen.add(c.name.toLowerCase())).toList();
    } catch (e) {
      logger.e('Error loading categories', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns [true] on success, [false] if a category with the same name already exists.
  Future<bool> addCategory(String name, String icon) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    final db = await _dbHelper.database;
    final existing = await db.query(
      'categories',
      where: 'LOWER(name) = ?',
      whereArgs: [trimmed.toLowerCase()],
    );

    if (existing.isNotEmpty) {
      logger.w('Category already exists: $trimmed');
      return false;
    }

    await db.insert('categories', {'name': trimmed, 'icon': icon});
    await loadCategories();
    return true;
  }

  Future<void> updateCategory(int id, String name, String icon) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      {'name': name, 'icon': icon},
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadCategories();
  }
}
