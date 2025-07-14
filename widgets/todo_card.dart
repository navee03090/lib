import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todo_master/models/todo.dart';
import 'package:todo_master/providers/todo_provider.dart';

// Create a stateful widget to prevent unnecessary rebuilds
class TodoCard extends StatelessWidget {
  final Todo todo;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelect;

  // Use constant constructor to allow for widget caching
  const TodoCard({
    super.key,
    required this.todo,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return _TodoCardContent(
      todo: todo,
      isSelectionMode: isSelectionMode,
      isSelected: isSelected,
      onSelect: onSelect,
    );
  }
}

// Use a separate stateful widget for content to enable memoization
class _TodoCardContent extends StatefulWidget {
  final Todo todo;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelect;

  const _TodoCardContent({
    required this.todo,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  State<_TodoCardContent> createState() => _TodoCardContentState();
}

class _TodoCardContentState extends State<_TodoCardContent> {
  // Cached values to prevent recalculation
  late final Color categoryColor = widget.todo.getCategoryColor();
  late final String categoryName = widget.todo.getCategoryName();
  late final String dueDateFormatted = DateFormat(
    'MMM dd, yyyy',
  ).format(widget.todo.dueDate);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      color:
          widget.isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.7)
              : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              widget.isSelected
                  ? theme.colorScheme.primary
                  : categoryColor.withOpacity(0.5),
          width: widget.isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.isSelectionMode ? widget.onSelect : null,
        onLongPress: !widget.isSelectionMode ? widget.onSelect : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selection checkbox or status checkbox
                  if (widget.isSelectionMode)
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: widget.isSelected,
                        onChanged: (_) => widget.onSelect?.call(),
                        activeColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    )
                  else
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: widget.todo.status == TodoStatus.completed,
                        onChanged: (_) {
                          _toggleStatus();
                        },
                        activeColor: categoryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),

                  // Drag handle icon - only show in non-selection mode
                  if (!widget.isSelectionMode)
                    Icon(
                      Icons.drag_handle,
                      color: isDark ? Colors.white38 : Colors.black26,
                      size: 20,
                    ),

                  // Todo title and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.todo.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration:
                                widget.todo.status == TodoStatus.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                            color:
                                widget.todo.status == TodoStatus.completed
                                    ? isDark
                                        ? Colors.white54
                                        : Colors.black54
                                    : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.todo.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Action buttons - only show in non-selection mode
                  if (!widget.isSelectionMode)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Notification Toggle
                        IconButton(
                          icon: Icon(
                            widget.todo.hasNotification
                                ? Icons.notifications_active_outlined
                                : Icons.notifications_off_outlined,
                            color:
                                widget.todo.hasNotification
                                    ? categoryColor
                                    : isDark
                                    ? Colors.white54
                                    : Colors.black38,
                          ),
                          onPressed:
                              widget.todo.status == TodoStatus.completed
                                  ? null
                                  : _toggleNotification,
                          tooltip:
                              widget.todo.hasNotification
                                  ? 'Disable notification'
                                  : 'Enable notification',
                        ),
                        // Delete button
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: isDark ? Colors.red.shade300 : Colors.red,
                          ),
                          onPressed: _deleteTodo,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Due date and category info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Due date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: _getDueDateColor(context, widget.todo.dueDate),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dueDateFormatted,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getDueDateColor(context, widget.todo.dueDate),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

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
                      categoryName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                      ),
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

  // Extract methods to improve readability and reduce duplicated code
  void _toggleStatus() {
    context.read<TodoProvider>().toggleTodoStatus(widget.todo.id);
  }

  void _toggleNotification() {
    context.read<TodoProvider>().toggleTodoNotification(widget.todo.id);
  }

  void _deleteTodo() {
    context.read<TodoProvider>().deleteTodo(widget.todo.id);
  }

  Color _getDueDateColor(BuildContext context, DateTime dueDate) {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If due date is past
    if (dueDate.isBefore(now) && widget.todo.status != TodoStatus.completed) {
      return isDark ? Colors.red.shade300 : Colors.red;
    }

    // If due date is today
    if (dueDate.day == now.day &&
        dueDate.month == now.month &&
        dueDate.year == now.year) {
      return isDark ? Colors.orange.shade300 : Colors.orange;
    }

    // If due date is in the future
    return isDark ? Colors.green.shade300 : Colors.green;
  }
}
