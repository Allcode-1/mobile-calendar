import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_calendar/presentation/screens/calendar/task_full_sheet.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/event_model.dart';
import '../../../logic/event_provider.dart';
import '../../../logic/auth_provider.dart';
import '../../widgets/textfield/quick_task_field.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final CategoryModel category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  final TextEditingController _taskController = TextEditingController();
  int _filterIndex = 0; // 0: All, 1: Active, 2: Done

  void _submitTask(String? userId) {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;

    final newEvent = EventModel(
      id: const Uuid().v4(),
      title: title,
      userId: userId ?? 'me',
      updatedAt: DateTime.now().toUtc(),
      categoryId: widget.category.id,
      isCompleted: false,
      isDeleted: false,
    );

    ref.read(eventProvider.notifier).addEvent(newEvent);
    _taskController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(eventProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id;

    // Фильтрация
    List<EventModel> tasks = eventState.events
        .where((e) => e.categoryId == widget.category.id)
        .toList();

    if (_filterIndex == 1) tasks = tasks.where((e) => !e.isCompleted).toList();
    if (_filterIndex == 2) tasks = tasks.where((e) => e.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: QuickTaskField(
                  controller: _taskController,
                  onSubmitted: () => _submitTask(currentUserId),
                ),
              ),
            ),

            _buildFilterSection(),

            tasks.isEmpty ? _buildEmptyState() : _buildTaskList(tasks),

            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Category",
                        style: TextStyle(
                          color: widget.category.flutterColor.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.category.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                Hero(
                  tag: 'cat_icon_${widget.category.id}',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.category.flutterColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.category.flutterColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      _getIconData(widget.category.icon),
                      color: widget.category.flutterColor,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _filterChip("All Quests", 0),
              _filterChip("Active", 1),
              _filterChip("Completed", 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, int index) {
    final isSelected = _filterIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filterIndex = index),
        backgroundColor: AppColors.surface,
        selectedColor: widget.category.flutterColor.withValues(alpha: 0.8),
        showCheckmark: false,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTaskList(List<EventModel> tasks) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final event = tasks[index];
          final isDone = event.isCompleted;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDone
                    ? widget.category.flutterColor.withValues(alpha: 0.3)
                    : AppColors.surfaceLight,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              leading: IconButton(
                icon: Icon(
                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isDone
                      ? widget.category.flutterColor
                      : AppColors.textSecondary,
                  size: 28,
                ),
                onPressed: () =>
                    ref.read(eventProvider.notifier).toggleComplete(event),
              ),
              title: Text(
                event.title,
                style: TextStyle(
                  color: isDone ? AppColors.textSecondary : Colors.white,
                  fontWeight: FontWeight.w600,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => _showEditDialog(context, event),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      color: AppColors.error,
                      size: 20,
                    ),
                    onPressed: () =>
                        ref.read(eventProvider.notifier).deleteEvent(event.id),
                  ),
                ],
              ),
            ),
          );
        }, childCount: tasks.length),
      ),
    );
  }

  void _showEditDialog(BuildContext context, EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskFullSheet(event: event),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Opacity(
          opacity: 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome_motion,
                size: 64,
                color: widget.category.flutterColor,
              ),
              const SizedBox(height: 16),
              const Text(
                "No tasks here yet",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home_filled;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'shopping':
        return Icons.shopping_bag;
      case 'fitness':
        return Icons.fitness_center;
      default:
        return Icons.folder_rounded;
    }
  }
}
