import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:todo_master/models/todo.dart';
import 'package:todo_master/services/firestore_service.dart';
import 'package:todo_master/services/notification_service.dart';

class TodoProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService.instance;
  final Uuid _uuid = const Uuid();

  List<Todo> _todos = [];
  bool _isLoading = false;

  // Filters
  TodoStatus? _statusFilter;
  TodoCategory? _categoryFilter;
  String _dateFilter = 'all'; // all, week, month

  // Cache filtered todos to avoid recomputing on every rebuild
  List<Todo>? _filteredTodosCache;
  bool _shouldInvalidateCache = true;

  List<Todo> get todos => _todos;
  bool get isLoading => _isLoading;
  TodoStatus? get statusFilter => _statusFilter;
  TodoCategory? get categoryFilter => _categoryFilter;
  String get dateFilter => _dateFilter;

  // Initialize with subscription to Firestore
  TodoProvider() {
    _initTodos();
  }

  void _initTodos() {
    _isLoading = true;
    notifyListeners();

    // Subscribe to todos from Firestore
    _firestoreService.getTodos().listen((todos) {
      _todos = todos;
      _shouldInvalidateCache = true;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Add a new todo
  Future<void> addTodo({
    required String title,
    required String description,
    required DateTime dueDate,
    required TodoCategory category,
    bool hasNotification = true,
  }) async {
    // Find the highest position value to add new todo at the end
    int highestPosition = 0;
    if (_todos.isNotEmpty) {
      highestPosition =
          _todos.map((t) => t.position).reduce((a, b) => a > b ? a : b) + 1;
    }

    final todo = Todo(
      id: _uuid.v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      category: category,
      hasNotification: hasNotification,
      position: highestPosition,
    );

    // Add to local list immediately for UI responsiveness
    _todos.add(todo);
    _shouldInvalidateCache = true;
    notifyListeners();

    try {
      // Then save to Firestore
      await _firestoreService.addTodo(todo);

      // Schedule notification if enabled
      if (hasNotification) {
        await _notificationService.scheduleTodoNotification(todo);
      }
    } catch (e) {
      // If Firestore save fails, remove from local list
      _todos.removeWhere((t) => t.id == todo.id);
      _shouldInvalidateCache = true;
      notifyListeners();
      // Rethrow to allow the UI to show error
      rethrow;
    }
  }

  // Update existing todo
  Future<void> updateTodo(Todo todo) async {
    // Find the index of the todo in the local list
    final index = _todos.indexWhere((t) => t.id == todo.id);

    // If the todo exists in the local list
    if (index != -1) {
      // Store the old version in case we need to rollback
      final oldTodo = _todos[index];

      // Update local list immediately
      _todos[index] = todo;
      notifyListeners();

      try {
        // Then update in Firestore
        await _firestoreService.updateTodo(todo);

        // Update notification
        await _notificationService.updateTodoNotification(todo);
      } catch (e) {
        // If Firestore update fails, rollback to old version
        _todos[index] = oldTodo;
        notifyListeners();
        rethrow;
      }
    } else {
      // If the todo is not in the local list, just try to update in Firestore
      await _firestoreService.updateTodo(todo);

      // Update notification
      await _notificationService.updateTodoNotification(todo);
    }
  }

  // Delete a todo
  Future<void> deleteTodo(String id) async {
    // Find the todo in the local list
    final index = _todos.indexWhere((t) => t.id == id);
    Todo? removedTodo;

    // If the todo exists in the local list
    if (index != -1) {
      // Store it in case we need to rollback
      removedTodo = _todos[index];

      // Remove from local list immediately
      _todos.removeAt(index);
      notifyListeners();

      // Cancel notification
      await _notificationService.cancelTodoNotification(removedTodo);
    }

    try {
      // Then delete from Firestore
      await _firestoreService.deleteTodo(id);
    } catch (e) {
      // If Firestore delete fails and we have the removed todo, add it back
      if (removedTodo != null) {
        _todos.insert(index, removedTodo);
        notifyListeners();

        // Reschedule notification if it had one
        if (removedTodo.hasNotification &&
            removedTodo.status == TodoStatus.pending) {
          await _notificationService.scheduleTodoNotification(removedTodo);
        }
      }
      rethrow;
    }
  }

  // Toggle todo status
  Future<void> toggleTodoStatus(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      final todo = _todos[index];
      final newStatus =
          todo.status == TodoStatus.completed
              ? TodoStatus.pending
              : TodoStatus.completed;

      // Create updated todo
      final updatedTodo = todo.copyWith(status: newStatus);

      // Store the old todo for potential rollback
      final oldTodo = _todos[index];

      // Update locally first
      _todos[index] = updatedTodo;
      notifyListeners();

      try {
        // Then update in Firestore
        await _firestoreService.updateTodo(updatedTodo);

        // Update notifications based on status
        if (updatedTodo.hasNotification) {
          if (updatedTodo.status == TodoStatus.completed) {
            // Cancel notification for completed tasks
            await _notificationService.cancelTodoNotification(updatedTodo);
          } else {
            // Schedule notification for pending tasks
            await _notificationService.scheduleTodoNotification(updatedTodo);
          }
        }
      } catch (e) {
        // Rollback on error
        _todos[index] = oldTodo;
        notifyListeners();
        rethrow;
      }
    }
  }

  // Toggle notification for a todo
  Future<void> toggleTodoNotification(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      final todo = _todos[index];
      final updatedTodo = todo.copyWith(hasNotification: !todo.hasNotification);

      // Store the old todo for potential rollback
      final oldTodo = _todos[index];

      // Update locally first
      _todos[index] = updatedTodo;
      notifyListeners();

      try {
        // Update in Firestore
        await _firestoreService.updateTodo(updatedTodo);

        // Update notification status
        if (updatedTodo.hasNotification &&
            updatedTodo.status == TodoStatus.pending) {
          await _notificationService.scheduleTodoNotification(updatedTodo);
        } else {
          await _notificationService.cancelTodoNotification(updatedTodo);
        }
      } catch (e) {
        // Rollback on error
        _todos[index] = oldTodo;
        notifyListeners();
        rethrow;
      }
    }
  }

  // Filters
  void setStatusFilter(TodoStatus? status) {
    if (_statusFilter == status) return; // Don't update if unchanged
    _statusFilter = status;
    _shouldInvalidateCache = true;
    notifyListeners();
  }

  void setCategoryFilter(TodoCategory? category) {
    if (_categoryFilter == category) return; // Don't update if unchanged
    _categoryFilter = category;
    _shouldInvalidateCache = true;
    notifyListeners();
  }

  void setDateFilter(String filter) {
    if (_dateFilter == filter) return; // Don't update if unchanged
    _dateFilter = filter;
    _shouldInvalidateCache = true;
    notifyListeners();
  }

  List<Todo> getFilteredTodos() {
    // Return cached result if available and cache is still valid
    if (!_shouldInvalidateCache && _filteredTodosCache != null) {
      return _filteredTodosCache!;
    }

    List<Todo> filteredTodos =
        _todos.where((todo) {
          // Apply status filter
          if (_statusFilter != null && todo.status != _statusFilter) {
            return false;
          }

          // Apply category filter
          if (_categoryFilter != null && todo.category != _categoryFilter) {
            return false;
          }

          // Apply date filter
          if (_dateFilter == 'week') {
            final now = DateTime.now();
            final weekEnd = now.add(const Duration(days: 7));
            return todo.dueDate.isAfter(
                  now.subtract(const Duration(days: 1)),
                ) &&
                todo.dueDate.isBefore(weekEnd);
          } else if (_dateFilter == 'month') {
            final now = DateTime.now();
            final monthEnd = DateTime(now.year, now.month + 1, 1);
            return todo.dueDate.isAfter(
                  now.subtract(const Duration(days: 1)),
                ) &&
                todo.dueDate.isBefore(monthEnd);
          }

          return true;
        }).toList();

    // Sort by position
    filteredTodos.sort((a, b) => a.position.compareTo(b.position));

    // Cache the result
    _filteredTodosCache = filteredTodos;
    _shouldInvalidateCache = false;

    return filteredTodos;
  }

  // Statistics methods
  int get totalTodos => _todos.length;

  int get completedTodos =>
      _todos.where((todo) => todo.status == TodoStatus.completed).length;

  int get pendingTodos =>
      _todos.where((todo) => todo.status == TodoStatus.pending).length;

  // Get todos count by category
  Map<String, int> getTodoCountByCategory() {
    final Map<String, int> result = {};

    for (final category in TodoCategory.values) {
      final count = _todos.where((todo) => todo.category == category).length;
      result[category.toString().split('.').last] = count;
    }

    return result;
  }

  // Get upcoming todos (due in the next 3 days)
  List<Todo> getUpcomingTodos() {
    final now = DateTime.now();
    final threeDaysLater = now.add(const Duration(days: 3));

    return _todos
        .where(
          (todo) =>
              todo.status == TodoStatus.pending &&
              todo.dueDate.isAfter(now) &&
              todo.dueDate.isBefore(threeDaysLater),
        )
        .toList();
  }

  // Get overdue todos
  List<Todo> getOverdueTodos() {
    final now = DateTime.now();

    return _todos
        .where(
          (todo) =>
              todo.status == TodoStatus.pending && todo.dueDate.isBefore(now),
        )
        .toList();
  }

  // Reorder todos in the list
  Future<void> reorderTodos(int oldIndex, int newIndex) async {
    // Adjust index if moving down
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // Get the list of filtered todos
    final todos = getFilteredTodos();

    // The todo being moved
    final Todo movedTodo = todos[oldIndex];

    // Remove from the old position
    todos.removeAt(oldIndex);

    // Insert at new position
    todos.insert(newIndex, movedTodo);

    // Update positions of all affected todos
    final updatedTodos = <Todo>[];
    for (int i = 0; i < todos.length; i++) {
      final currentTodo = todos[i];
      // Only update if position changed
      if (currentTodo.position != i) {
        updatedTodos.add(currentTodo.copyWith(position: i));
      }
    }

    // Update locally first
    for (final updatedTodo in updatedTodos) {
      final index = _todos.indexWhere((t) => t.id == updatedTodo.id);
      if (index != -1) {
        _todos[index] = updatedTodo;
      }
    }

    // Invalidate cache
    _shouldInvalidateCache = true;
    notifyListeners();

    // Update in Firestore
    try {
      for (final updatedTodo in updatedTodos) {
        await _firestoreService.updateTodo(updatedTodo);
      }
    } catch (e) {
      // If Firestore update fails, refresh the list from Firestore
      _initTodos();
      rethrow;
    }
  }
}
