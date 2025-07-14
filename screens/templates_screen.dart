import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_master/models/task_template.dart';
import 'package:todo_master/models/todo.dart';
import 'package:todo_master/providers/template_provider.dart';
import 'package:todo_master/providers/todo_provider.dart';
import 'package:todo_master/widgets/responsive_builder.dart';
import 'package:uuid/uuid.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TodoCategory _selectedCategory = TodoCategory.personal;
  String _iconName = 'bookmark';
  bool _isEditing = false;
  String? _editingTemplateId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showTemplateForm({TaskTemplate? template}) {
    // Reset form or fill with template data
    _isEditing = template != null;
    _editingTemplateId = template?.id;
    _titleController.text = template?.title ?? '';
    _descriptionController.text = template?.description ?? '';
    _selectedCategory = template?.category ?? TodoCategory.personal;
    _iconName = template?.iconName ?? 'bookmark';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isEditing ? 'Edit Template' : 'New Template',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Template title
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                          autofocus: true,
                        ),
                        const SizedBox(height: 16),

                        // Template description
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // Category dropdown
                        DropdownButtonFormField<TodoCategory>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items:
                              TodoCategory.values.map((category) {
                                // Create a sample todo to get color and name
                                final sampleTodo = Todo(
                                  id: '',
                                  title: '',
                                  description: '',
                                  dueDate: DateTime.now(),
                                  category: category,
                                );

                                return DropdownMenuItem(
                                  value: category,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: sampleTodo.getCategoryColor(),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(sampleTodo.getCategoryName()),
                                    ],
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  ElevatedButton(
                    onPressed: () => _saveTemplate(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _isEditing ? 'UPDATE TEMPLATE' : 'SAVE TEMPLATE',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _saveTemplate(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      final templateProvider = context.read<TemplateProvider>();

      final template = TaskTemplate(
        id: _isEditing ? _editingTemplateId! : const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        iconName: _iconName,
      );

      if (_isEditing) {
        templateProvider.updateTemplate(template);
      } else {
        templateProvider.addTemplate(template);
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Template updated successfully!'
                : 'Template saved successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _confirmDeleteTemplate(BuildContext context, TaskTemplate template) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Template'),
            content: Text(
              'Are you sure you want to delete "${template.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  context.read<TemplateProvider>().deleteTemplate(template.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Template deleted!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                child: const Text('DELETE'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );
  }

  void _useTemplate(TaskTemplate template) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((selectedDate) {
      if (selectedDate != null) {
        final todoProvider = context.read<TodoProvider>();
        final todo = template.toTodo(
          id: const Uuid().v4(),
          dueDate: selectedDate,
        );

        todoProvider.addTodo(
          title: todo.title,
          description: todo.description,
          dueDate: todo.dueDate,
          category: todo.category,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task created from template!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Template',
            onPressed: () => _showTemplateForm(),
          ),
        ],
      ),
      body: Consumer<TemplateProvider>(
        builder: (context, templateProvider, child) {
          if (templateProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final templates = templateProvider.templates;

          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_outline,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No templates yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a template for tasks you create often',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showTemplateForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Template'),
                  ),
                ],
              ),
            );
          }

          return ResponsiveBuilder(
            builder: (context, screenSize) {
              if (screenSize == ScreenSize.large) {
                // Grid view for larger screens
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3 / 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    return _buildTemplateCard(templates[index]);
                  },
                );
              }

              // List view for smaller screens
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  return _buildTemplateCard(templates[index]);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTemplateForm(),
        tooltip: 'Add Template',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTemplateCard(TaskTemplate template) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get the todo's category color
    final sampleTodo = Todo(
      id: '',
      title: '',
      description: '',
      dueDate: DateTime.now(),
      category: template.category,
    );
    final categoryColor = sampleTodo.getCategoryColor();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: categoryColor.withOpacity(0.5), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _useTemplate(template),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and actions
              Row(
                children: [
                  Icon(Icons.bookmark, color: categoryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      template.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    splashRadius: 20,
                    tooltip: 'Edit',
                    onPressed: () => _showTemplateForm(template: template),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    splashRadius: 20,
                    tooltip: 'Delete',
                    color: isDark ? Colors.red.shade300 : Colors.red,
                    onPressed: () => _confirmDeleteTemplate(context, template),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                template.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 24),

              // Footer with category and use button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: categoryColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      sampleTodo.getCategoryName(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Use button
                  ElevatedButton.icon(
                    onPressed: () => _useTemplate(template),
                    icon: const Icon(Icons.add_task, size: 18),
                    label: const Text('Use'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
