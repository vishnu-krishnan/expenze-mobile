class Wish {
  final int? id;
  final String name;
  final double amount;
  final String? sourceLink;
  final String? notes;
  final bool isCompleted;
  final String? createdAt;
  final String? updatedAt;

  Wish({
    this.id,
    required this.name,
    required this.amount,
    this.sourceLink,
    this.notes,
    this.isCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'source_link': sourceLink,
      'notes': notes,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory Wish.fromMap(Map<String, dynamic> map) {
    return Wish(
      id: map['id'],
      name: map['name'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      sourceLink: map['source_link'],
      notes: map['notes'],
      isCompleted: map['is_completed'] == 1,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Wish copyWith({
    int? id,
    String? name,
    double? amount,
    String? sourceLink,
    String? notes,
    bool? isCompleted,
    String? createdAt,
    String? updatedAt,
  }) {
    return Wish(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      sourceLink: sourceLink ?? this.sourceLink,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
