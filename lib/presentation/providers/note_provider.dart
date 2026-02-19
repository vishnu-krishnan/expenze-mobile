import 'package:flutter/material.dart';
import 'package:expenze_mobile/data/repositories/note_repository.dart';
import 'package:expenze_mobile/data/models/note.dart';

import 'package:expenze_mobile/data/services/notification_service.dart';

class NoteProvider with ChangeNotifier {
  final NoteRepository _repository = NoteRepository();
  List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notes = await _repository.getAllNotes();
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNote(String title, String content,
      {DateTime? reminderDate, bool isPinned = false, String? color}) async {
    final now = DateTime.now();
    final note = Note(
      title: title,
      content: content,
      reminderDate: reminderDate,
      isReminderActive: reminderDate != null,
      isPinned: isPinned,
      color: color,
      createdAt: now,
      updatedAt: now,
    );
    final id = await _repository.insertNote(note);
    if (reminderDate != null) {
      await NotificationService().scheduleNotification(
        id: id,
        title: title,
        body: content,
        scheduledDate: reminderDate,
      );
    }
    await loadNotes();
  }

  Future<void> updateNote(Note note) async {
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    await _repository.updateNote(updatedNote);

    // Handle notification
    await NotificationService().cancelNotification(note.id!);
    if (note.isReminderActive &&
        note.reminderDate != null &&
        note.reminderDate!.isAfter(DateTime.now())) {
      await NotificationService().scheduleNotification(
        id: note.id!,
        title: note.title,
        body: note.content,
        scheduledDate: note.reminderDate!,
      );
    }

    await loadNotes();
  }

  Future<void> deleteNote(int id) async {
    await NotificationService().cancelNotification(id);
    await _repository.deleteNote(id);
    await loadNotes();
  }
// ...

  Future<void> togglePin(Note note) async {
    await updateNote(note.copyWith(isPinned: !note.isPinned));
  }
}
