import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/event_model.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/category_provider.dart';
import '../../../logic/event_provider.dart';
import 'detail_screen.dart';
import 'create_category_sheet.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final categoryState = ref.watch(categoryProvider);
    final allEvents = ref.watch(eventProvider).events;
    final userName = authState.user?.fullName ?? "Explorer";

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        heroTag: 'category_fab',
        backgroundColor: AppColors.primary,
        onPressed: () => _showCreateCategorySheet(context),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(categoryProvider.notifier).loadCategories(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, $userName!",
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 18,
                        ),
                      ),
                      const Text(
                        "Categories",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              categoryState.isLoading && categoryState.categories.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.72,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildCategoryCard(
                            categoryState.categories[index],
                            allEvents,
                          ),
                          childCount: categoryState.categories.length,
                        ),
                      ),
                    ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    CategoryModel category,
    List<EventModel> allEvents,
  ) {
    final catEvents = allEvents
        .where((e) => e.categoryId == category.id)
        .toList();
    final completed = catEvents.where((e) => e.isCompleted).length;
    final now = DateTime.now();
    final todayCount = catEvents.where((e) {
      if (e.startTime == null) return false;
      return e.startTime!.year == now.year &&
          e.startTime!.month == now.month &&
          e.startTime!.day == now.day;
    }).length;

    return GestureDetector(
      onLongPress: () => _showFocusDialog(
        context,
        category,
        catEvents.length,
        completed,
        todayCount,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(category: category),
          ),
        );
      },
      child: _buildCardUI(category, catEvents.length, completed, todayCount),
    );
  }

  Widget _buildCardUI(
    CategoryModel category,
    int total,
    int completed,
    int today,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: category.flutterColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconMapper.getIcon(category.icon),
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const Spacer(),
          Text(
            category.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _statRow("Tasks", total),
          _statRow("Completed", completed),
          _statRow("For today", today),
        ],
      ),
    );
  }

  void _showFocusDialog(
    BuildContext context,
    CategoryModel category,
    int total,
    int completed,
    int today,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, anim, a2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12 * anim.value,
            sigmaY: 12 * anim.value,
          ),
          child: FadeTransition(
            opacity: anim,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: (MediaQuery.of(context).size.width * 0.75) / 0.72,
                    child: _buildCardUI(category, total, completed, today),
                  ),
                  const SizedBox(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _actionButton(
                        icon: Icons.edit_outlined,
                        color: Colors.white,
                        bgColor: Colors.blue.withValues(alpha: 0.4),
                        onTap: () {
                          Navigator.pop(context);
                          _showCreateCategorySheet(context, category: category);
                        },
                      ),
                      const SizedBox(width: 30),
                      _actionButton(
                        icon: Icons.delete_outline_rounded,
                        color: Colors.white,
                        bgColor: Colors.red.withValues(alpha: 0.4),
                        onTap: () async {
                          await ref
                              .read(categoryProvider.notifier)
                              .deleteCategory(category.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$label: $count",
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showCreateCategorySheet(
    BuildContext context, {
    CategoryModel? category,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => CreateCategorySheet(category: category),
    );
  }
}
