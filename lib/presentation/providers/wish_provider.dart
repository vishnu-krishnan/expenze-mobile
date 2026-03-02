import 'package:flutter/foundation.dart';
import '../../data/models/wish.dart';
import '../../data/services/database_helper.dart';
import '../../core/utils/logger.dart';

class WishProvider extends ChangeNotifier {
  List<Wish> _wishes = [];
  bool _isLoading = false;

  List<Wish> get wishes => _wishes;
  bool get isLoading => _isLoading;

  Future<void> loadWishes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final dbHelper = DatabaseHelper.instance;
      final wishesMap = await dbHelper.getWishes();
      _wishes = wishesMap.map((m) => Wish.fromMap(m)).toList();
    } catch (e) {
      logger.e('Error loading wishes', error: e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addWish(Wish wish) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final id = await dbHelper.insertWish(wish.toMap());
      final newWish = wish.copyWith(id: id);
      _wishes.insert(0, newWish);
      notifyListeners();
    } catch (e) {
      logger.e('Error adding wish', error: e);
    }
  }

  Future<void> updateWish(Wish wish) async {
    if (wish.id == null) return;
    try {
      final dbHelper = DatabaseHelper.instance;
      final updateData = wish.toMap();
      updateData['updated_at'] = DateTime.now().toIso8601String();
      await dbHelper.updateWish(wish.id!, updateData);

      final index = _wishes.indexWhere((n) => n.id == wish.id);
      if (index != -1) {
        _wishes[index] = wish.copyWith(updatedAt: updateData['updated_at']);
        notifyListeners();
      }
    } catch (e) {
      logger.e('Error updating wish', error: e);
    }
  }

  Future<void> deleteWish(int id) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteWish(id);
      _wishes.removeWhere((w) => w.id == id);
      notifyListeners();
    } catch (e) {
      logger.e('Error deleting wish', error: e);
    }
  }

  Future<void> toggleWishStatus(Wish wish) async {
    final updatedWish = wish.copyWith(isCompleted: !wish.isCompleted);
    await updateWish(updatedWish);
  }
}
