import 'package:flutter/material.dart';
import 'package:expenze_mobile/data/repositories/note_repository.dart';
import 'package:expenze_mobile/data/models/note.dart';

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
    await _repository.insertNote(note);
    await loadNotes();
  }

  Future<void> updateNote(Note note) async {
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    await _repository.updateNote(updatedNote);
    await loadNotes();
  }

  Future<void> deleteNote(int id) async {
    await _repository.deleteNote(id);
    await loadNotes();
  }

  Future<void> togglePin(Note note) async {
    await updateNote(note.copyWith(isPinned: !note.isPinned));
  }
}
