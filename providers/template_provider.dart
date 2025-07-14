import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_master/models/task_template.dart';
import 'package:todo_master/models/todo.dart';
import 'package:uuid/uuid.dart';

class TemplateProvider extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  final List<TaskTemplate> _templates = [];
  static const String _storageKey = 'task_templates';
  bool _isLoading = true;

  List<TaskTemplate> get templates => _templates;
  bool get isLoading => _isLoading;

  // Initialize by loading templates from storage
  TemplateProvider() {
    _loadTemplates();
  }

  // Load templates from SharedPreferences
  Future<void> _loadTemplates() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesJson = prefs.getStringList(_storageKey);

      if (templatesJson != null) {
        _templates.clear();
        for (final json in templatesJson) {
          final map = jsonDecode(json) as Map<String, dynamic>;
          _templates.add(TaskTemplate.fromMap(map));
        }
      } else {
        // Add some default templates for first-time users
        _addDefaultTemplates();
      }
    } catch (e) {
      debugPrint('Error loading templates: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save templates to SharedPreferences
  Future<void> _saveTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesJson =
          _templates.map((t) => jsonEncode(t.toMap())).toList();
      await prefs.setStringList(_storageKey, templatesJson);
    } catch (e) {
      debugPrint('Error saving templates: $e');
    }
  }

  // Add predefined templates for new users
  void _addDefaultTemplates() {
    final defaults = [
      TaskTemplate(
        id: _uuid.v4(),
        title: 'Work Meeting',
        description: 'Regular team meeting',
        category: TodoCategory.work,
        iconName: 'work',
      ),
      TaskTemplate(
        id: _uuid.v4(),
        title: 'Grocery Shopping',
        description: 'Buy weekly groceries',
        category: TodoCategory.shopping,
        iconName: 'shopping_cart',
      ),
      TaskTemplate(
        id: _uuid.v4(),
        title: 'Doctor Appointment',
        description: 'Regular checkup',
        category: TodoCategory.health,
        iconName: 'favorite',
      ),
    ];

    _templates.addAll(defaults);
    _saveTemplates();
  }

  // Add a new template
  Future<void> addTemplate(TaskTemplate template) async {
    _templates.add(template);
    notifyListeners();
    await _saveTemplates();
  }

  // Create a template from a Todo
  Future<void> createTemplateFromTodo(Todo todo, {String? name}) async {
    final template = TaskTemplate.fromTodo(
      todo,
      id: _uuid.v4(),
      iconName: 'bookmark',
    );

    await addTemplate(template);
  }

  // Update an existing template
  Future<void> updateTemplate(TaskTemplate template) async {
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _templates[index] = template;
      notifyListeners();
      await _saveTemplates();
    }
  }

  // Delete a template
  Future<void> deleteTemplate(String id) async {
    _templates.removeWhere((t) => t.id == id);
    notifyListeners();
    await _saveTemplates();
  }

  // Get a template by its id
  TaskTemplate? getTemplateById(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}
