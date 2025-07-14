import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_master/models/todo.dart';
import 'package:todo_master/widgets/custom_button.dart';
import 'package:todo_master/widgets/custom_text_field.dart';

class TodoForm extends StatefulWidget {
  final Function(
    String title,
    String description,
    DateTime dueDate,
    TodoCategory category,
    bool hasNotification,
  )
  onSubmit;
  final String? initialTitle;
  final String? initialDescription;
  final DateTime? initialDueDate;
  final TodoCategory? initialCategory;
  final bool? initialHasNotification;
  final bool isEditing;
  final String submitLabel;

  const TodoForm({
    Key? key,
    required this.onSubmit,
    this.initialTitle,
    this.initialDescription,
    this.initialDueDate,
    this.initialCategory,
    this.initialHasNotification,
    this.isEditing = false,
    this.submitLabel = 'Save',
  }) : super(key: key);

  @override
  State<TodoForm> createState() => _TodoFormState();
}

class _TodoFormState extends State<TodoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  late TodoCategory _category;
  late bool _hasNotification;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );

    // Set due date and time
    final now = DateTime.now();
    final initialDate =
        widget.initialDueDate ??
        DateTime(now.year, now.month, now.day, now.hour + 1, 0);
    _dueDate = DateTime(initialDate.year, initialDate.month, initialDate.day);
    _dueTime = TimeOfDay(hour: initialDate.hour, minute: initialDate.minute);

    // Set category and notification
    _category = widget.initialCategory ?? TodoCategory.personal;
    _hasNotification = widget.initialHasNotification ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  DateTime _getFullDueDateTime() {
    return DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
      _dueTime.hour,
      _dueTime.minute,
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final DateTime dueDateTime = _getFullDueDateTime();

      widget.onSubmit(
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        dueDateTime,
        _category,
        _hasNotification,
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title field
          CustomTextField(
            controller: _titleController,
            labelText: 'Title',
            hintText: 'Enter task title',
            prefixIcon: Icon(Icons.title, color: theme.colorScheme.primary),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description field
          CustomTextField(
            controller: _descriptionController,
            labelText: 'Description',
            hintText: 'Enter task description',
            maxLines: 3,
            prefixIcon: Icon(
              Icons.description,
              color: theme.colorScheme.primary,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Due date and time
          Text('Due Date & Time', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd, yyyy').format(_dueDate),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _pickTime(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _dueTime.format(context),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category dropdown
          Text('Category', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TodoCategory>(
                value: _category,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.primary,
                ),
                items:
                    TodoCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color:
                                    Todo(
                                      id: '',
                                      title: '',
                                      description: '',
                                      dueDate: DateTime.now(),
                                      category: category,
                                    ).getCategoryColor(),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              Todo(
                                id: '',
                                title: '',
                                description: '',
                                dueDate: DateTime.now(),
                                category: category,
                              ).getCategoryName(),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (newCategory) {
                  if (newCategory != null) {
                    setState(() {
                      _category = newCategory;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notification setting
          SwitchListTile(
            title: Text(
              'Enable Notifications',
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              'You will be notified 1 hour before the due time',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            value: _hasNotification,
            activeColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (bool value) {
              setState(() {
                _hasNotification = value;
              });
            },
          ),
          const SizedBox(height: 24),

          // Submit button
          CustomButton(
            text: widget.submitLabel,
            onPressed: _handleSubmit,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
