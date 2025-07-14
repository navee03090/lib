// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:todo_master/models/todo.dart';
import 'package:todo_master/providers/todo_provider.dart';
import 'package:todo_master/widgets/responsive_builder.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        // Show loading indicator when loading from Firestore
        if (todoProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading statistics...'),
              ],
            ),
          );
        }

        return ResponsiveBuilder(
          builder: (context, screenSize) {
            if (screenSize == ScreenSize.small) {
              return _buildMobileLayout(context, todoProvider);
            } else {
              return _buildTabletDesktopLayout(context, todoProvider);
            }
          },
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, TodoProvider todoProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        _buildSummaryCards(context, todoProvider),

        const SizedBox(height: 24),

        // Status chart (Pie chart)
        _buildStatusChartCard(context, todoProvider),

        const SizedBox(height: 24),

        // Category distribution (Bar chart)
        _buildCategoryChartCard(context, todoProvider),

        const SizedBox(height: 24),

        // Task insights
        _buildInsightsCard(context, todoProvider),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTabletDesktopLayout(
    BuildContext context,
    TodoProvider todoProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          _buildSummaryCards(context, todoProvider),

          const SizedBox(height: 24),

          // Charts and insights in a row
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Status chart
                Expanded(
                  flex: 1,
                  child: _buildStatusChartCard(context, todoProvider),
                ),

                const SizedBox(width: 16),

                // Right column - Category chart and insights
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Category chart
                      Expanded(
                        flex: 3,
                        child: _buildCategoryChartCard(context, todoProvider),
                      ),

                      const SizedBox(height: 16),

                      // Insights
                      Expanded(
                        flex: 2,
                        child: _buildInsightsCard(context, todoProvider),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChartCard(
    BuildContext context,
    TodoProvider todoProvider,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 200,
              child: _buildStatusPieChart(context, todoProvider),
            ),

            const SizedBox(height: 16),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  context,
                  'Completed',
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.green.shade300
                      : Colors.green,
                ),
                const SizedBox(width: 24),
                _buildLegendItem(
                  context,
                  'Pending',
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.orange.shade300
                      : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChartCard(
    BuildContext context,
    TodoProvider todoProvider,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Distribution',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 250, // Fixed height instead of Expanded
              child: _buildCategoryBarChart(context, todoProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context, TodoProvider todoProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Insights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Remove Expanded and use SizedBox with fixed height or Container
            SizedBox(
              height: 180, // Fixed height instead of Expanded
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Most active category
                    _buildInsightItem(
                      context,
                      'Most Active Category',
                      _getMostActiveCategory(todoProvider),
                      Icons.category,
                    ),

                    const Divider(height: 24),

                    // Upcoming deadlines
                    _buildInsightItem(
                      context,
                      'Upcoming Tasks',
                      '${todoProvider.getUpcomingTodos().length} due in next 3 days',
                      Icons.upcoming,
                    ),

                    const Divider(height: 24),

                    // Overdue tasks
                    _buildInsightItem(
                      context,
                      'Overdue Tasks',
                      '${todoProvider.getOverdueTodos().length} tasks overdue',
                      Icons.warning_amber_rounded,
                      color:
                          todoProvider.getOverdueTodos().isNotEmpty
                              ? isDark
                                  ? Colors.red.shade300
                                  : Colors.red
                              : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, TodoProvider todoProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            'Total',
            todoProvider.totalTodos.toString(),
            Icons.checklist_rounded,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Completed',
            todoProvider.completedTodos.toString(),
            Icons.check_circle_outline,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Pending',
            todoProvider.pendingTodos.toString(),
            Icons.pending_actions,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get the appropriate shade based on color type
    Color getShadeColor(Color baseColor) {
      if (baseColor is MaterialColor) {
        return isDark ? baseColor.shade300 : baseColor;
      } else {
        return isDark ? baseColor.withOpacity(0.7) : baseColor;
      }
    }

    final shadeColor = getShadeColor(color);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: shadeColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: shadeColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPieChart(BuildContext context, TodoProvider todoProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final completedTodos = todoProvider.completedTodos;
    final pendingTodos = todoProvider.pendingTodos;

    // If no todos, show empty state
    if (completedTodos == 0 && pendingTodos == 0) {
      return Center(
        child: Text('No data to display', style: theme.textTheme.bodyLarge),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            title: '$completedTodos',
            value: completedTodos.toDouble(),
            color: isDark ? Colors.green.shade300 : Colors.green,
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            title: '$pendingTodos',
            value: pendingTodos.toDouble(),
            color: isDark ? Colors.orange.shade300 : Colors.orange,
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBarChart(
    BuildContext context,
    TodoProvider todoProvider,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categoryData = todoProvider.getTodoCountByCategory();
    final categories = categoryData.keys.toList();

    // If no categories, show empty state
    if (categories.isEmpty) {
      return Center(
        child: Text('No data to display', style: theme.textTheme.bodyLarge),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            categoryData.values.fold(
              0,
              (max, count) => count > max ? count : max,
            ) *
            1.2,
        barGroups: List.generate(categories.length, (index) {
          final category = categories[index];
          final count = categoryData[category] ?? 0;
          final todo = Todo(
            id: '',
            title: '',
            description: '',
            dueDate: DateTime.now(),
            category: TodoCategory.values.firstWhere(
              (e) => e.toString().split('.').last == category,
            ),
          );

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: todo.getCategoryColor(),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= categories.length) {
                  return const SizedBox();
                }

                final category = categories[index];
                final displayName =
                    category.substring(0, 1).toUpperCase() +
                    (category.length > 3
                        ? category.substring(1, 4)
                        : category.substring(1));

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    displayName,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const SizedBox();
                }

                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildInsightItem(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: color ?? theme.colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMostActiveCategory(TodoProvider todoProvider) {
    final categoryData = todoProvider.getTodoCountByCategory();
    if (categoryData.isEmpty) {
      return 'None';
    }

    // Find category with most todos
    String? mostActiveCategory;
    int maxCount = 0;

    categoryData.forEach((category, count) {
      if (count > maxCount) {
        maxCount = count;
        mostActiveCategory = category;
      }
    });

    if (mostActiveCategory == null) {
      return 'None';
    }

    // Format the category name
    final formattedCategory =
        mostActiveCategory!.substring(0, 1).toUpperCase() +
        mostActiveCategory!.substring(1);

    return '$formattedCategory ($maxCount tasks)';
  }
}
