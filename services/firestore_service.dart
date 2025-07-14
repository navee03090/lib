import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:todo_master/models/todo.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for category stats to avoid redundant queries
  Map<String, int>? _categoryCountCache;
  DateTime? _categoryCountCacheTime;

  // Cache for overdue todos
  List<Todo>? _overdueTodosCache;
  DateTime? _overdueTodosCacheTime;

  // Cache for upcoming todos
  List<Todo>? _upcomingTodosCache;
  DateTime? _upcomingTodosCacheTime;

  // Cache expiration duration
  static const cacheDuration = Duration(minutes: 5);

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _todosCollection {
    // User-specific todos collection
    return _firestore
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .collection('todos');
  }

  // Get all todos for the current user
  Stream<List<Todo>> getTodos() {
    if (_auth.currentUser == null) {
      return Stream.value([]);
    }

    // Optimize the query to get Firestore data more efficiently
    return _todosCollection
        .orderBy('position') // Order by position first
        .orderBy('dueDate') // Then by due date as a secondary sort
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return Todo.fromMap(doc.data());
                } catch (e) {
                  print("⚠️ Skipping broken todo: $e");
                  return null;
                }
              })
              .whereType<Todo>()
              .toList();
        });
  }

  // Add a new todo
  Future<void> addTodo(Todo todo) async {
    if (_auth.currentUser == null) return;

    // Invalidate caches when adding a todo
    _invalidateCaches();

    await _todosCollection.doc(todo.id).set(todo.toMap());
  }

  // Update an existing todo
  Future<void> updateTodo(Todo todo) async {
    if (_auth.currentUser == null) return;

    // Invalidate caches when updating a todo
    _invalidateCaches();

    await _todosCollection.doc(todo.id).update(todo.toMap());
  }

  // Delete a todo
  Future<void> deleteTodo(String id) async {
    if (_auth.currentUser == null) return;

    // Invalidate caches when deleting a todo
    _invalidateCaches();

    await _todosCollection.doc(id).delete();
  }

  // Helper method to invalidate all caches
  void _invalidateCaches() {
    _categoryCountCache = null;
    _categoryCountCacheTime = null;
    _overdueTodosCache = null;
    _overdueTodosCacheTime = null;
    _upcomingTodosCache = null;
    _upcomingTodosCacheTime = null;
  }

  // Get todo count by category for statistics
  Future<Map<String, int>> getTodoCountByCategory() async {
    if (_auth.currentUser == null) return {};

    // Check if cache is valid
    final now = DateTime.now();
    if (_categoryCountCache != null &&
        _categoryCountCacheTime != null &&
        now.difference(_categoryCountCacheTime!) < cacheDuration) {
      return _categoryCountCache!;
    }

    final Map<String, int> result = {};

    // More efficient batch query using where-in clause
    final snapshot = await _todosCollection.get();
    final todos = snapshot.docs.map((doc) => Todo.fromMap(doc.data())).toList();

    // Count categories locally
    for (final todo in todos) {
      final categoryName = todo.category.toString().split('.').last;
      result[categoryName] = (result[categoryName] ?? 0) + 1;
    }

    // Update cache
    _categoryCountCache = result;
    _categoryCountCacheTime = now;

    return result;
  }

  // Get overdue todos
  Future<List<Todo>> getOverdueTodos() async {
    if (_auth.currentUser == null) return [];

    // Check if cache is valid
    final now = DateTime.now();
    if (_overdueTodosCache != null &&
        _overdueTodosCacheTime != null &&
        now.difference(_overdueTodosCacheTime!) < cacheDuration) {
      return _overdueTodosCache!;
    }

    final snapshot =
        await _todosCollection
            .where('status', isEqualTo: TodoStatus.pending.index)
            .where('dueDate', isLessThan: now.millisecondsSinceEpoch)
            .get();

    final result =
        snapshot.docs.map((doc) => Todo.fromMap(doc.data())).toList();

    // Update cache
    _overdueTodosCache = result;
    _overdueTodosCacheTime = now;

    return result;
  }

  // Get upcoming todos (next 3 days)
  Future<List<Todo>> getUpcomingTodos() async {
    if (_auth.currentUser == null) return [];

    // Check if cache is valid
    final now = DateTime.now();
    if (_upcomingTodosCache != null &&
        _upcomingTodosCacheTime != null &&
        now.difference(_upcomingTodosCacheTime!) < cacheDuration) {
      return _upcomingTodosCache!;
    }

    final threeDaysLater = now.add(const Duration(days: 3));

    final snapshot =
        await _todosCollection
            .where('status', isEqualTo: TodoStatus.pending.index)
            .where('dueDate', isGreaterThan: now.millisecondsSinceEpoch)
            .where('dueDate', isLessThan: threeDaysLater.millisecondsSinceEpoch)
            .get();

    final result =
        snapshot.docs.map((doc) => Todo.fromMap(doc.data())).toList();

    // Update cache
    _upcomingTodosCache = result;
    _upcomingTodosCacheTime = now;

    return result;
  }
}
