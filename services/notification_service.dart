import 'package:todo_master/models/todo.dart';

/// A simple notification service stub that logs notifications instead of showing them
/// This allows the app to build without compatibility issues
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  NotificationService._();

  Future<void> initialize() async {
    print('NotificationService initialized (stub implementation)');
  }

  // Log a notification instead of showing it
  Future<void> scheduleTodoNotification(Todo todo) async {
    // Don't schedule notifications for completed tasks
    if (todo.status == TodoStatus.completed || !todo.hasNotification) {
      return;
    }

    // Log the notification details
    print(
      'NOTIFICATION: Task reminder for "${todo.title}" due ${_getFormattedDueTime(todo.dueDate)}',
    );

    // In a real implementation, this would show or schedule an actual notification
  }

  // Log notification cancellation
  Future<void> cancelTodoNotification(Todo todo) async {
    print('NOTIFICATION CANCELLED: Task "${todo.title}"');
  }

  // Update notification when task is updated
  Future<void> updateTodoNotification(Todo todo) async {
    // First cancel existing notification
    await cancelTodoNotification(todo);

    // Then schedule a new one if task is pending and has notifications enabled
    if (todo.status == TodoStatus.pending && todo.hasNotification) {
      await scheduleTodoNotification(todo);
    }
  }

  // Helper to format the due time for notification
  String _getFormattedDueTime(DateTime dueDate) {
    final now = DateTime.now();

    // If due today
    if (dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day) {
      return 'today at ${_formatTime(dueDate)}';
    }

    // If due tomorrow
    final tomorrow = now.add(const Duration(days: 1));
    if (dueDate.year == tomorrow.year &&
        dueDate.month == tomorrow.month &&
        dueDate.day == tomorrow.day) {
      return 'tomorrow at ${_formatTime(dueDate)}';
    }

    // Otherwise show date and time
    return '${_formatDate(dueDate)} at ${_formatTime(dueDate)}';
  }

  // Format time as HH:MM AM/PM
  String _formatTime(DateTime date) {
    final hour =
        date.hour > 12
            ? date.hour - 12
            : date.hour == 0
            ? 12
            : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Format date as Month Day, Year
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
