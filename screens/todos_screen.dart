import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_master/models/todo.dart';
import 'package:todo_master/providers/todo_provider.dart';
import 'package:todo_master/widgets/responsive_builder.dart';
import 'package:todo_master/widgets/todo_card.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show lerpDouble;

class TodosScreen extends StatefulWidget {
  final TodoStatus? statusFilter;

  const TodosScreen({super.key, this.statusFilter});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  // Selection mode state
  bool _isSelectionMode = false;
  final Set<String> _selectedTodoIds = {};

  // Focus node for keyboard shortcuts
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Set the status filter based on the screen type
    Future.microtask(() {
      context.read<TodoProvider>().setStatusFilter(widget.statusFilter);
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedTodoIds.clear();
    });
  }

  void _toggleTodoSelection(String todoId) {
    setState(() {
      if (_selectedTodoIds.contains(todoId)) {
        _selectedTodoIds.remove(todoId);
      } else {
        _selectedTodoIds.add(todoId);
      }

      // Exit selection mode if nothing is selected
      if (_selectedTodoIds.isEmpty && _isSelectionMode) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAll(List<Todo> todos) {
    setState(() {
      if (_selectedTodoIds.length == todos.length) {
        // If all are selected, unselect all
        _selectedTodoIds.clear();
      } else {
        // Otherwise select all
        _selectedTodoIds.clear();
        for (final todo in todos) {
          _selectedTodoIds.add(todo.id);
        }
      }
    });
  }

  Future<void> _completeBatchTodos() async {
    final todoProvider = context.read<TodoProvider>();

    // Create a copy to avoid concurrent modification
    final selectedIds = List.from(_selectedTodoIds);

    // Show loading dialog
    _showLoadingDialog();

    try {
      for (final id in selectedIds) {
        // Only update if not already completed
        final todo = todoProvider.todos.firstWhere((todo) => todo.id == id);
        if (todo.status != TodoStatus.completed) {
          await todoProvider.toggleTodoStatus(id);
        }
      }

      // Exit selection mode
      setState(() {
        _isSelectionMode = false;
        _selectedTodoIds.clear();
      });
    } catch (e) {
      // Show error
      _showErrorSnackBar('Failed to update tasks: ${e.toString()}');
    } finally {
      // Close dialog
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _deleteBatchTodos() async {
    final todoProvider = context.read<TodoProvider>();

    // Create a copy to avoid concurrent modification
    final selectedIds = List.from(_selectedTodoIds);

    // Confirm deletion
    final confirmed = await _showConfirmationDialog(
      'Delete ${selectedIds.length} tasks?',
      'This action cannot be undone.',
    );

    if (confirmed != true) return;

    // Show loading dialog
    _showLoadingDialog();

    try {
      for (final id in selectedIds) {
        await todoProvider.deleteTodo(id);
      }

      // Exit selection mode
      setState(() {
        _isSelectionMode = false;
        _selectedTodoIds.clear();
      });
    } catch (e) {
      // Show error
      _showErrorSnackBar('Failed to delete tasks: ${e.toString()}');
    } finally {
      // Close dialog
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 24),
                Text('Processing...'),
              ],
            ),
          ),
    );
  }

  Future<bool?> _showConfirmationDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('DELETE'),
              ),
            ],
          ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Handle keyboard shortcuts
  KeyEventResult _handleKeyboardShortcuts(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      // Get the provider outside conditional to avoid multiple reads
      final todoProvider = context.read<TodoProvider>();
      final todos = todoProvider.getFilteredTodos();

      // Check if control or meta (command) key is pressed
      final isControlOrMeta =
          HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      // CTRL/CMD + A: Toggle select all
      if (event.logicalKey == LogicalKeyboardKey.keyA && isControlOrMeta) {
        _selectAll(todos);
        return KeyEventResult.handled;
      }

      // ESC: Exit selection mode
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_isSelectionMode) {
          _toggleSelectionMode();
          return KeyEventResult.handled;
        }
      }

      // CTRL/CMD + D: Delete selected
      if (event.logicalKey == LogicalKeyboardKey.keyD && isControlOrMeta) {
        if (_isSelectionMode && _selectedTodoIds.isNotEmpty) {
          _deleteBatchTodos();
          return KeyEventResult.handled;
        }
      }

      // CTRL/CMD + E: Complete selected
      if (event.logicalKey == LogicalKeyboardKey.keyE && isControlOrMeta) {
        if (_isSelectionMode && _selectedTodoIds.isNotEmpty) {
          _completeBatchTodos();
          return KeyEventResult.handled;
        }
      }

      // CTRL/CMD + S: Toggle selection mode
      if (event.logicalKey == LogicalKeyboardKey.keyS && isControlOrMeta) {
        _toggleSelectionMode();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  // Show keyboard shortcuts helper dialog
  void _showKeyboardShortcutsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Keyboard Shortcuts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _ShortcutItem(
                shortcut: 'Ctrl/⌘ + S',
                description: 'Toggle selection mode',
              ),
              _ShortcutItem(
                shortcut: 'Ctrl/⌘ + A',
                description: 'Select all tasks',
              ),
              _ShortcutItem(
                shortcut: 'Esc',
                description: 'Exit selection mode',
              ),
              _ShortcutItem(
                shortcut: 'Ctrl/⌘ + E',
                description: 'Complete selected tasks',
              ),
              _ShortcutItem(
                shortcut: 'Ctrl/⌘ + D',
                description: 'Delete selected tasks',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyboardShortcuts,
      child: ResponsiveBuilder(
        builder: (context, screenSize) {
          // For medium and large screens, use a different layout
          if (screenSize == ScreenSize.medium ||
              screenSize == ScreenSize.large) {
            return _buildTabletDesktopLayout();
          }

          // For small screens (mobile), use the original layout
          return _buildMobileLayout();
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Filters section
        _buildFilters(),

        // Todos list
        Expanded(
          child: Consumer<TodoProvider>(
            builder: (context, todoProvider, _) {
              final todos = todoProvider.getFilteredTodos();

              return Stack(
                children: [
                  _TodoListView(
                    isSelectionMode: _isSelectionMode,
                    selectedTodoIds: _selectedTodoIds,
                    onTodoToggle: _toggleTodoSelection,
                  ),

                  // Show batch action buttons when in selection mode
                  if (_isSelectionMode)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: _buildBatchActionButtons(todos),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabletDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar with filters
        SizedBox(
          width: 300,
          child: Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildFilters(isVertical: true),
            ),
          ),
        ),

        // Todos list
        Expanded(
          child: Consumer<TodoProvider>(
            builder: (context, todoProvider, _) {
              final todos = todoProvider.getFilteredTodos();

              return Stack(
                children: [
                  _TodoListView(
                    isSelectionMode: _isSelectionMode,
                    selectedTodoIds: _selectedTodoIds,
                    onTodoToggle: _toggleTodoSelection,
                  ),

                  // Show batch action buttons when in selection mode
                  if (_isSelectionMode)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: _buildBatchActionButtons(todos),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBatchActionButtons(List<Todo> todos) {
    final theme = Theme.of(context);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Selection count and select all
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      '${_selectedTodoIds.length}/${todos.length} selected',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _selectedTodoIds.length == todos.length
                          ? Icons.select_all
                          : Icons.deselect,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () => _selectAll(todos),
                    tooltip:
                        _selectedTodoIds.length == todos.length
                            ? 'Deselect all'
                            : 'Select all',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleSelectionMode,
                    tooltip: 'Exit selection mode',
                  ),
                  // Keyboard shortcuts help button (for desktop)
                  IconButton(
                    icon: const Icon(Icons.keyboard),
                    onPressed: _showKeyboardShortcutsDialog,
                    tooltip: 'Keyboard shortcuts',
                  ),
                ],
              ),
            ),

            // Action buttons
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Complete selected
                  ActionChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.done_all,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        const Text('Complete'),
                      ],
                    ),
                    onPressed:
                        _selectedTodoIds.isEmpty ? null : _completeBatchTodos,
                  ),
                  const SizedBox(width: 8),
                  // Delete selected
                  ActionChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete,
                          color: theme.colorScheme.error,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        const Text('Delete'),
                      ],
                    ),
                    onPressed:
                        _selectedTodoIds.isEmpty ? null : _deleteBatchTodos,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters({bool isVertical = false}) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final filters = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time filter (All, This Week, This Month)
            Text('Time Period', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),

            SingleChildScrollView(
              scrollDirection: isVertical ? Axis.vertical : Axis.horizontal,
              child:
                  isVertical
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildTimeFilterChips(todoProvider),
                      )
                      : Row(children: _buildTimeFilterChips(todoProvider)),
            ),

            const SizedBox(height: 16),

            // Category filter
            Text('Categories', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),

            SingleChildScrollView(
              scrollDirection: isVertical ? Axis.vertical : Axis.horizontal,
              child:
                  isVertical
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildCategoryFilterChips(todoProvider),
                      )
                      : Row(children: _buildCategoryFilterChips(todoProvider)),
            ),
          ],
        );

        if (isVertical) {
          return filters;
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: filters,
        );
      },
    );
  }

  List<Widget> _buildTimeFilterChips(TodoProvider todoProvider) {
    return [
      _buildFilterChip(
        label: 'All',
        selected: todoProvider.dateFilter == 'all',
        onSelected: (selected) {
          todoProvider.setDateFilter('all');
        },
      ),
      SizedBox(width: 8, height: 8),
      _buildFilterChip(
        label: 'This Week',
        selected: todoProvider.dateFilter == 'week',
        onSelected: (selected) {
          todoProvider.setDateFilter('week');
        },
      ),
      SizedBox(width: 8, height: 8),
      _buildFilterChip(
        label: 'This Month',
        selected: todoProvider.dateFilter == 'month',
        onSelected: (selected) {
          todoProvider.setDateFilter('month');
        },
      ),
    ];
  }

  List<Widget> _buildCategoryFilterChips(TodoProvider todoProvider) {
    final chips = <Widget>[
      _buildFilterChip(
        label: 'All',
        selected: todoProvider.categoryFilter == null,
        onSelected: (selected) {
          todoProvider.setCategoryFilter(null);
        },
      ),
    ];

    for (final category in TodoCategory.values) {
      final todo = Todo(
        id: '',
        title: '',
        description: '',
        dueDate: DateTime.now(),
        category: category,
      );

      chips.add(SizedBox(width: 8, height: 8));

      chips.add(
        _buildFilterChip(
          label: todo.getCategoryName(),
          selected: todoProvider.categoryFilter == category,
          color: todo.getCategoryColor(),
          onSelected: (selected) {
            todoProvider.setCategoryFilter(selected ? category : null);
          },
        ),
      );
    }

    return chips;
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color:
              selected
                  ? isDark
                      ? Colors.black
                      : Colors.white
                  : color ?? (isDark ? Colors.white70 : Colors.black87),
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor:
          color != null
              ? color.withOpacity(0.2)
              : isDark
              ? Colors.grey[800]
              : Colors.grey[200],
      selectedColor: color ?? theme.colorScheme.primary,
      checkmarkColor: isDark ? Colors.black : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

// Separated stateful widget for the todo list to avoid unnecessary rebuilds
class _TodoListView extends StatelessWidget {
  final bool isSelectionMode;
  final Set<String> selectedTodoIds;
  final Function(String) onTodoToggle;

  const _TodoListView({
    this.isSelectionMode = false,
    this.selectedTodoIds = const {},
    required this.onTodoToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        // Show loading indicator when loading data from Firestore
        if (todoProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading tasks...'),
              ],
            ),
          );
        }

        final todos = todoProvider.getFilteredTodos();

        if (todos.isEmpty) {
          return const _EmptyTodoList();
        }

        return Column(
          children: [
            // Add selection mode toggle button
            if (!isSelectionMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.select_all),
                      label: const Text('Select'),
                      onPressed: () {
                        (context as Element)
                            .findAncestorStateOfType<_TodosScreenState>()
                            ?._toggleSelectionMode();
                      },
                    ),
                  ],
                ),
              ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // In a real app, refresh data from API or database
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                // Use ReorderableListView instead of ListView.builder
                child: ReorderableListView.builder(
                  itemCount: todos.length,
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  proxyDecorator: (child, index, animation) {
                    // Custom appearance while dragging
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (BuildContext context, Widget? child) {
                        final double animValue = Curves.easeInOut.transform(
                          animation.value,
                        );
                        final double elevation = lerpDouble(1, 6, animValue)!;
                        final double scale = lerpDouble(1.0, 1.02, animValue)!;

                        return Transform.scale(
                          scale: scale,
                          child: Material(
                            elevation: elevation,
                            color: Colors.transparent,
                            child: child,
                          ),
                        );
                      },
                      child: child,
                    );
                  },
                  // Build list items
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return TodoCard(
                      key: ValueKey(todo.id),
                      todo: todo,
                      isSelectionMode: isSelectionMode,
                      isSelected: selectedTodoIds.contains(todo.id),
                      onSelect: () => onTodoToggle(todo.id),
                    );
                  },
                  // Handle reordering
                  onReorder: (oldIndex, newIndex) {
                    // Only allow reordering if not in selection mode
                    if (!isSelectionMode) {
                      todoProvider.reorderTodos(oldIndex, newIndex);
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Extract empty state to a separate widget for better performance
class _EmptyTodoList extends StatelessWidget {
  const _EmptyTodoList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No todos found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a new todo or change filters',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// Helper widget for displaying keyboard shortcuts
class _ShortcutItem extends StatelessWidget {
  final String shortcut;
  final String description;

  const _ShortcutItem({required this.shortcut, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            child: Text(
              shortcut,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(description),
        ],
      ),
    );
  }
}
