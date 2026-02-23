import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'data/services/database_helper.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await DatabaseHelper.instance.database;
  try {
    await db.insert('users', {'email': 'test@example.com', 'full_name': 'Test'});
    print('Insert ok');
  } catch (e) {
    print('Insert err: $e');
  }
}
