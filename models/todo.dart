import 'package:flutter/material.dart';

enum TodoStatus { pending, completed }

enum TodoCategory { personal, work, shopping, health, other }

class Todo {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TodoCategory category;
  final TodoStatus status;
  final DateTime createdAt;
  final bool hasNotification;
  final int position;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.category,
    this.status = TodoStatus.pending,
    DateTime? createdAt,
    this.hasNotification = true,
    this.position = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TodoCategory? category,
    TodoStatus? status,
    DateTime? createdAt,
    bool? hasNotification,
    int? position,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      hasNotification: hasNotification ?? this.hasNotification,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'category': category.index,
      'status': status.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'hasNotification': hasNotification,
      'position': position,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      category: TodoCategory.values[map['category']],
      status: TodoStatus.values[map['status']],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      hasNotification: map['hasNotification'] ?? true,
      position: map['position'] ?? 0,
    );
  }

  Color getCategoryColor() {
    switch (category) {
      case TodoCategory.personal:
        return Colors.blue;
      case TodoCategory.work:
        return Colors.orange;
      case TodoCategory.shopping:
        return Colors.green;
      case TodoCategory.health:
        return Colors.red;
      case TodoCategory.other:
        return Colors.purple;
    }
  }

  String getCategoryName() {
    switch (category) {
      case TodoCategory.personal:
        return 'Personal';
      case TodoCategory.work:
        return 'Work';
      case TodoCategory.shopping:
        return 'Shopping';
      case TodoCategory.health:
        return 'Health';
      case TodoCategory.other:
        return 'Other';
    }
  }
}
