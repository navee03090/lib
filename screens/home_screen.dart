import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_master/models/task_template.dart';
import 'package:todo_master/models/todo.dart';
import 'package:todo_master/providers/template_provider.dart';
import 'package:todo_master/providers/theme_provider.dart';
import 'package:todo_master/providers/todo_provider.dart';
import 'package:todo_master/screens/add_todo_screen.dart';
import 'package:todo_master/screens/settings_screen.dart';
import 'package:todo_master/screens/stats_screen.dart';
import 'package:todo_master/screens/templates_screen.dart';
import 'package:todo_master/screens/todos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Quick add form controllers
  final TextEditingController _quickTitleController = TextEditingController();
  final TextEditingController _quickDescController = TextEditingController();
  TodoCategory _quickCategory = TodoCategory.personal;
  final _quickFormKey = GlobalKey<FormState>();
  bool _isQuickAddLoading = false;

  // Define the screens for each tab
  late final List<Widget> _screens = [
    const TodosScreen(), // All todos
    const TodosScreen(statusFilter: TodoStatus.pending), // Pending todos
    const TodosScreen(statusFilter: TodoStatus.completed), // Completed todos
    const TemplatesScreen(), // Templates
    const StatsScreen(), // Statistics
    const SettingsScreen(), // Settings
  ];

  // Titles for each tab
  final List<String> _titles = [
    'All Tasks',
    'Pending',
    'Completed',
    'Templates',
    'Statistics',
    'Settings',
  ];

  @override
  void dispose() {
    _quickTitleController.dispose();
    _quickDescController.dispose();
    super.dispose();
  }

  void _showQuickAddSheet() {
    // Clear previous values
    _quickTitleController.clear();
    _quickDescController.clear();
    _quickCategory = TodoCategory.personal;
    _isQuickAddLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final templateProvider = Provider.of<TemplateProvider>(
              context,
              listen: false,
            );
            final templates = templateProvider.templates;

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
                        'Quick Add Task',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  // Template selector
                  if (templates.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        // Show template selector
                        _showTemplateSelector(context, (template) {
                          setState(() {
                            _quickTitleController.text = template.title;
                            _quickDescController.text = template.description;
                            _quickCategory = template.category;
                          });
                          Navigator.pop(context); // Close the template selector
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Use a template',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.bookmark_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                  ],

                  const SizedBox(height: 8),
                  Form(
                    key: _quickFormKey,
                    child: Column(
                      children: [
                        // Task title
                        TextFormField(
                          controller: _quickTitleController,
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
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Task description
                        TextFormField(
                          controller: _quickDescController,
                          decoration: const InputDecoration(
                            labelText: 'Description (optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // Category dropdown
                        DropdownButtonFormField<TodoCategory>(
                          value: _quickCategory,
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
                                _quickCategory = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Add button
                  ElevatedButton(
                    onPressed:
                        _isQuickAddLoading
                            ? null
                            : () => _submitQuickAdd(setState),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child:
                        _isQuickAddLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                              'ADD TASK',
                              style: TextStyle(fontSize: 16),
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

  void _showTemplateSelector(
    BuildContext context,
    Function(TaskTemplate) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final templateProvider = Provider.of<TemplateProvider>(context);
        final templates = templateProvider.templates;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Template',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (templateProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (templates.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.bookmark_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No templates available',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create templates in the Templates tab',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: templates.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      // Sample todo for color
                      final todo = Todo(
                        id: '',
                        title: '',
                        description: '',
                        dueDate: DateTime.now(),
                        category: template.category,
                      );
                      final categoryColor = todo.getCategoryColor();

                      return ListTile(
                        leading: Icon(Icons.bookmark, color: categoryColor),
                        title: Text(
                          template.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          template.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: categoryColor.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            todo.getCategoryName(),
                            style: TextStyle(
                              color: categoryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () => onSelect(template),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitQuickAdd(StateSetter setState) async {
    // Validate form
    if (_quickFormKey.currentState?.validate() != true) {
      return;
    }

    // Set loading state
    setState(() {
      _isQuickAddLoading = true;
    });

    try {
      // Create and add todo
      await context.read<TodoProvider>().addTodo(
        title: _quickTitleController.text.trim(),
        description: _quickDescController.text.trim(),
        dueDate: DateTime.now().add(const Duration(days: 1)),
        category: _quickCategory,
      );

      // Show success message
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Reset loading state if sheet is still open
      setState(() {
        _isQuickAddLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        actions: [
          // Add task button
          if (_currentIndex <= 2)
            IconButton(
              icon: const Icon(Icons.add_task),
              tooltip: 'Quick Add',
              onPressed: _showQuickAddSheet,
            ),
          // Theme toggle button
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
        ],
      ),

      // Body changes based on selected tab
      body: _screens[_currentIndex],

      // Floating action button for adding new todos
      // Only show on the todo list screens
      floatingActionButton:
          _currentIndex <= 2
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTodoScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              )
              : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'All'),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions),
            label: 'Pending',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Completed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            label: 'Templates',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
