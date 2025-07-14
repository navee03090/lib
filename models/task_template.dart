import 'package:todo_master/models/todo.dart';

class TaskTemplate {
  final String id;
  final String title;
  final String description;
  final TodoCategory category;
  final String iconName;

  const TaskTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.iconName = 'bookmark',
  });

  // Convert template to a Todo object
  Todo toTodo({
    required String id,
    DateTime? dueDate,
    bool hasNotification = true,
  }) {
    return Todo(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
      category: category,
      hasNotification: hasNotification,
    );
  }

  // Convert template to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.index,
      'iconName': iconName,
    };
  }

  // Create a template from a map
  factory TaskTemplate.fromMap(Map<String, dynamic> map) {
    return TaskTemplate(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: TodoCategory.values[map['category']],
      iconName: map['iconName'] ?? 'bookmark',
    );
  }

  // Create a copy of this template with updated fields
  TaskTemplate copyWith({
    String? id,
    String? title,
    String? description,
    TodoCategory? category,
    String? iconName,
  }) {
    return TaskTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
    );
  }

  // Create a template from a todo
  factory TaskTemplate.fromTodo(
    Todo todo, {
    required String id,
    String? iconName,
  }) {
    return TaskTemplate(
      id: id,
      title: todo.title,
      description: todo.description,
      category: todo.category,
      iconName: iconName ?? 'bookmark',
    );
  }
}
