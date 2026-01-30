import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_calendar/presentation/screens/calendar/task_full_sheet.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/event_model.dart';
import '../../../logic/event_provider.dart';
import '../../../logic/category_provider.dart';
import '../../../logic/auth_provider.dart';
import '../../widgets/textfield/quick_task_field.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _taskController = TextEditingController();
  String? _selectedCategoryId;

  void _submitQuickTask(String? userId) {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;

    final newEvent = EventModel(
      id: const Uuid().v4(),
      title: title,
      userId: userId ?? 'me',
      updatedAt: DateTime.now(),
      categoryId: _selectedCategoryId,
      isCompleted: false,
      isDeleted: false,
    );

    ref.read(eventProvider.notifier).addEvent(newEvent);
    _taskController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(eventProvider);
    final categoryState = ref.watch(categoryProvider);
    final authState = ref.watch(authProvider);

    final userName = authState.user?.fullName ?? "Explorer";
    final currentUserId = authState.user?.id;

    final filteredEvents = _selectedCategoryId == null
        ? eventState.events
        : eventState.events
              .where((e) => e.categoryId == _selectedCategoryId)
              .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(eventProvider.notifier).refreshEvents(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildHeader(userName, eventState.events),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: QuickTaskField(
                    controller: _taskController,
                    onSubmitted: () => _submitQuickTask(currentUserId),
                  ),
                ),
              ),

              _buildCategoryFilter(categoryState),

              _buildEventList(eventState, filteredEvents),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, List<EventModel> events) {
    final total = events.length;
    final completed = events.where((e) => e.isCompleted).length;
    final progress = total == 0 ? 0.0 : completed / total;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, $name!",
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
              ),
            ),
            const Text(
              "Quest Progress",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, Color(0xFF8E88FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${(progress * 100).toInt()}% Completed",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$completed of $total tasks done",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 44,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(CategoryState state) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              "Categories",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _categoryChip("All Tasks", null);
                final cat = state.categories[index - 1];
                return _categoryChip(cat.name, cat.id, color: cat.flutterColor);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, String? id, {Color? color}) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategoryId = id),
        backgroundColor: AppColors.surface,
        selectedColor: color?.withOpacity(0.8) ?? AppColors.primary,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEventList(EventState state, List<EventModel> filtered) {
    if (state.isLoading && state.events.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (filtered.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            "No quests found",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final event = filtered[index];
          final isDone = event.isCompleted;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDone
                    ? AppColors.primary.withOpacity(0.3)
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
                  color: isDone ? AppColors.secondary : AppColors.textSecondary,
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

              subtitle: event.description != null
                  ? Text(
                      event.description!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    )
                  : null,

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
        }, childCount: filtered.length),
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
}
