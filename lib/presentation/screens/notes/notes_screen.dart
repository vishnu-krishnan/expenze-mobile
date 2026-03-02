import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/note.dart';
import '../../../presentation/providers/note_provider.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  int? _editingNoteId;
  bool _isAddingNew = false;
  bool _isFabVisible = true;

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteProvider>().loadNotes();
    });
  }

  void _startEditing(Note? note) {
    setState(() {
      if (note == null) {
        _isAddingNew = true;
        _editingNoteId = null;
      } else {
        _isAddingNew = false;
        _editingNoteId = note.id;
      }
      _titleController.text = note?.title ?? '';
      _contentController.text = note?.content ?? '';
      _selectedDate = note?.reminderDate;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isAddingNew = false;
      _editingNoteId = null;
    });
  }

  void _saveNote(Note? note) {
    if (_titleController.text.isNotEmpty ||
        _contentController.text.isNotEmpty) {
      if (note == null) {
        context.read<NoteProvider>().addNote(
              _titleController.text,
              _contentController.text,
              reminderDate: _selectedDate,
            );
      } else {
        context.read<NoteProvider>().updateNote(
              note.copyWith(
                title: _titleController.text,
                content: _contentController.text,
                reminderDate: _selectedDate,
                isReminderActive: _selectedDate != null,
              ),
            );
      }
    }
    _cancelEditing();
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, String itemName) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final textColor = AppTheme.getTextColor(context);
        final secondaryTextColor =
            AppTheme.getTextColor(context, isSecondary: true);
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Delete \'$itemName\'?',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete this? This action cannot be undone.',
            style: TextStyle(color: secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Delete',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: Column(
          children: [
            AppBar(
              title: Text('Notes',
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 34,
                      letterSpacing: -1)),
              centerTitle: false,
              titleSpacing: 26,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 100,
            ),
            Expanded(
              child: Consumer<NoteProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (provider.notes.isEmpty && !_isAddingNew) {
                    return _buildEmptyState(secondaryTextColor);
                  }

                  final itemCount =
                      provider.notes.length + (_isAddingNew ? 1 : 0);

                  return NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      if (notification is ScrollUpdateNotification) {
                        if (notification.scrollDelta != null) {
                          if (notification.scrollDelta! > 2 && _isFabVisible) {
                            setState(() => _isFabVisible = false);
                          } else if (notification.scrollDelta! < -2 &&
                              !_isFabVisible) {
                            setState(() => _isFabVisible = true);
                          }
                        }
                      }
                      return false;
                    },
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 10,
                          bottom:
                              MediaQuery.of(context).viewInsets.bottom + 120),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        if (_isAddingNew && index == 0) {
                          return _buildEditableCard(
                              null, textColor, secondaryTextColor);
                        }

                        final noteIndex = _isAddingNew ? index - 1 : index;
                        final note = provider.notes[noteIndex];

                        if (_editingNoteId == note.id) {
                          return _buildEditableCard(
                              note, textColor, secondaryTextColor);
                        }

                        return _buildNoteCard(
                            note, textColor, secondaryTextColor);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isFabVisible ? 1.0 : 0.0,
            child: FloatingActionButton(
              heroTag: 'notes_fab',
              onPressed: () {
                if (!_isAddingNew && _editingNoteId == null) {
                  _startEditing(null);
                }
              },
              backgroundColor: AppTheme.primary,
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child:
                  const Icon(LucideIcons.plus, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color secondaryTextColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.stickyNote,
              size: 64, color: secondaryTextColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Your brain called — it wants backup.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: secondaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Jot down thoughts, reminders, or\nwhy you spent ₹2,000 on that thing.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: secondaryTextColor.withValues(alpha: 0.6), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note, Color textColor, Color secondaryTextColor) {
    final colorVal = note.color != null
        ? Color(int.parse(note.color!.replaceFirst('#', '0xff')))
        : AppTheme.primary;

    return Container(
      key: ValueKey('note-${note.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: colorVal.withValues(alpha: 0.8),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'Untitled' : note.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: textColor),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        note.isPinned ? LucideIcons.pin : LucideIcons.pinOff,
                        size: 20,
                        color: note.isPinned
                            ? AppTheme.primary
                            : secondaryTextColor.withValues(alpha: 0.3),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          context.read<NoteProvider>().togglePin(note),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  note.content,
                  style: TextStyle(
                      color: secondaryTextColor, fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (note.reminderDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.bell,
                                size: 14, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('MMM d, h:mm a')
                                  .format(note.reminderDate!),
                              style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _startEditing(note),
                          child: Icon(LucideIcons.edit2,
                              size: 18, color: secondaryTextColor),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () async {
                            final confirm = await _showDeleteConfirmation(
                                context,
                                note.title.isEmpty ? 'Untitled' : note.title);
                            if (confirm == true) {
                              context.read<NoteProvider>().deleteNote(note.id!);
                            }
                          },
                          child: const Icon(LucideIcons.trash2,
                              size: 18, color: AppTheme.danger),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCard(
      Note? note, Color textColor, Color secondaryTextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: TextStyle(
                              color: secondaryTextColor.withValues(alpha: 0.5)),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: secondaryTextColor,
                      onPressed: _cancelEditing,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(LucideIcons.list, size: 18),
                      color: AppTheme.primary,
                      tooltip: 'Bullet List',
                      onPressed: () {
                        if (_contentController.text.isEmpty ||
                            _contentController.text.endsWith('\n')) {
                          _contentController.text += '• ';
                        } else {
                          _contentController.text += '\n• ';
                        }
                        _contentController.selection = TextSelection.collapsed(
                            offset: _contentController.text.length);
                      },
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(LucideIcons.listOrdered, size: 18),
                      color: AppTheme.primary,
                      tooltip: 'Numbered List',
                      onPressed: () {
                        if (_contentController.text.isEmpty ||
                            _contentController.text.endsWith('\n')) {
                          _contentController.text += '1. ';
                        } else {
                          _contentController.text += '\n1. ';
                        }
                        _contentController.selection = TextSelection.collapsed(
                            offset: _contentController.text.length);
                      },
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          if (!context.mounted) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _selectedDate != null
                                ? TimeOfDay.fromDateTime(_selectedDate!)
                                : TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              _selectedDate = DateTime(date.year, date.month,
                                  date.day, time.hour, time.minute);
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedDate != null
                              ? AppTheme.primary.withValues(alpha: 0.1)
                              : secondaryTextColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.bell,
                                size: 14,
                                color: _selectedDate != null
                                    ? AppTheme.primary
                                    : secondaryTextColor),
                            if (_selectedDate != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('MMM d, h:mm a')
                                    .format(_selectedDate!),
                                style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contentController,
                  maxLines: null,
                  minLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Content...',
                    hintStyle: TextStyle(
                        color: secondaryTextColor.withValues(alpha: 0.5)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(color: textColor, height: 1.6),
                  onChanged: (val) {
                    if (val.endsWith('\n')) {
                      final lines = val.split('\n');
                      if (lines.length >= 2) {
                        final prevLine = lines[lines.length - 2];
                        if (prevLine.trim() == '•') {
                          _contentController.text =
                              val.substring(0, val.length - 2);
                          _contentController.selection =
                              TextSelection.collapsed(
                                  offset: _contentController.text.length);
                        } else if (prevLine.trimLeft().startsWith('• ')) {
                          _contentController.text = val + '• ';
                          _contentController.selection =
                              TextSelection.collapsed(
                                  offset: _contentController.text.length);
                        } else {
                          final match = RegExp(r'^(\d+)\.\s')
                              .firstMatch(prevLine.trimLeft());
                          if (match != null) {
                            if (prevLine.trim() == match.group(0)!.trim()) {
                              _contentController.text = val.substring(
                                  0, val.length - match.group(0)!.length - 1);
                              _contentController.selection =
                                  TextSelection.collapsed(
                                      offset: _contentController.text.length);
                            } else {
                              final num = int.parse(match.group(1)!) + 1;
                              _contentController.text = val + '$num. ';
                              _contentController.selection =
                                  TextSelection.collapsed(
                                      offset: _contentController.text.length);
                            }
                          }
                        }
                      }
                    }
                  },
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _saveNote(note),
                    style: AppTheme.primaryButtonStyle.copyWith(
                        padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12)),
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)))),
                    child: Text('Done',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
