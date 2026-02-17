import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:expenze_mobile/presentation/providers/note_provider.dart';
import 'package:expenze_mobile/presentation/providers/theme_provider.dart';
import 'package:expenze_mobile/core/theme/app_theme.dart';
import 'package:expenze_mobile/data/models/note.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteProvider>().loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    final isDark = themeProvider.isDarkMode;

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
              title: Text('Utilities',
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      letterSpacing: -1)),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            Expanded(
              child: Consumer<NoteProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.notes.isEmpty) {
                    return _buildEmptyState(secondaryTextColor);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    itemCount: provider.notes.length,
                    itemBuilder: (context, index) {
                      return _buildNoteCard(
                          provider.notes[index], textColor, secondaryTextColor);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(context),
        backgroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(LucideIcons.plus, color: Colors.white, size: 30),
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
            'Keep track of your thoughts\nand important reminders',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryTextColor, fontSize: 16),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: colorVal.withValues(alpha: 0.5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: textColor),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        note.isPinned ? LucideIcons.pin : LucideIcons.pinOff,
                        size: 18,
                        color: note.isPinned
                            ? AppTheme.primary
                            : secondaryTextColor.withValues(alpha: 0.5),
                      ),
                      onPressed: () =>
                          context.read<NoteProvider>().togglePin(note),
                    ),
                  ],
                ),
                Text(
                  note.content,
                  style: TextStyle(color: secondaryTextColor, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (note.reminderDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.bell,
                                size: 12, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, h:mm a')
                                  .format(note.reminderDate!),
                              style: const TextStyle(
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
                        IconButton(
                          icon: Icon(LucideIcons.edit2,
                              size: 16, color: secondaryTextColor),
                          onPressed: () => _showNoteDialog(context, note: note),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2,
                              size: 16, color: AppTheme.danger),
                          onPressed: () =>
                              context.read<NoteProvider>().deleteNote(note.id!),
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

  void _showNoteDialog(BuildContext context, {Note? note}) {
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    DateTime? selectedDate = note?.reminderDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final modalBgColor = isDark ? AppTheme.bgCardDark : Colors.white;
          final textColor = AppTheme.getTextColor(context);

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: modalBgColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note == null ? 'New Note' : 'Edit Note',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    decoration: AppTheme.inputDecoration(
                        'Title', LucideIcons.type,
                        context: context),
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: AppTheme.inputDecoration(
                        'Content', LucideIcons.alignLeft,
                        context: context),
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(LucideIcons.bell, color: AppTheme.primary),
                    title: Text(
                        selectedDate == null
                            ? 'Set Reminder'
                            : DateFormat('MMM d, yyyy h:mm a')
                                .format(selectedDate!),
                        style: TextStyle(color: textColor)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedDate != null
                              ? TimeOfDay.fromDateTime(selectedDate!)
                              : TimeOfDay.now(),
                        );
                        if (time != null) {
                          setModalState(() {
                            selectedDate = DateTime(date.year, date.month,
                                date.day, time.hour, time.minute);
                          });
                        }
                      }
                    },
                    trailing: selectedDate != null
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () =>
                                setModalState(() => selectedDate = null))
                        : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty ||
                            contentController.text.isNotEmpty) {
                          if (note == null) {
                            context.read<NoteProvider>().addNote(
                                  titleController.text,
                                  contentController.text,
                                  reminderDate: selectedDate,
                                );
                          } else {
                            context.read<NoteProvider>().updateNote(
                                  note.copyWith(
                                    title: titleController.text,
                                    content: contentController.text,
                                    reminderDate: selectedDate,
                                    isReminderActive: selectedDate != null,
                                  ),
                                );
                          }
                          Navigator.pop(context);
                        }
                      },
                      child:
                          Text(note == null ? 'Create Note' : 'Save Changes'),
                    ),
                  ),
                  const SizedBox(height: 48), // Bottom safe area
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
