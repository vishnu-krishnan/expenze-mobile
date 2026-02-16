class Note {
  final int? id;
  final String title;
  final String content;
  final DateTime? reminderDate;
  final bool isReminderActive;
  final bool isPinned;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    this.id,
    required this.title,
    required this.content,
    this.reminderDate,
    this.isReminderActive = false,
    this.isPinned = false,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'reminder_date': reminderDate?.toIso8601String(),
      'is_reminder_active': isReminderActive ? 1 : 0,
      'is_pinned': isPinned ? 1 : 0,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      reminderDate: map['reminder_date'] != null
          ? DateTime.parse(map['reminder_date'] as String)
          : null,
      isReminderActive: (map['is_reminder_active'] as int? ?? 0) == 1,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      color: map['color'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? reminderDate,
    bool? isReminderActive,
    bool? isPinned,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      reminderDate: reminderDate ?? this.reminderDate,
      isReminderActive: isReminderActive ?? this.isReminderActive,
      isPinned: isPinned ?? this.isPinned,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
