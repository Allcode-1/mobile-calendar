import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/app_logger.dart';
import '../data/models/category_model.dart';
import '../data/repositories/category_repository.dart';
import 'auth_provider.dart';

class CategoryState {
  final List<CategoryModel> categories;
  final bool isLoading;
  final String? error;

  CategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  CategoryNotifier(this._repository, this._ref) : super(CategoryState()) {
    loadCategories();
  }

  final CategoryRepository _repository;
  final Ref _ref;
  String? get _currentUserId => _ref.read(authProvider).user?.id;

  Future<void> loadCategories() async {
    if (!mounted) return;
    state = CategoryState(categories: state.categories, isLoading: true);

    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) {
        state = CategoryState(categories: const [], isLoading: false);
        return;
      }

      if (!kIsWeb) {
        final localCategories = await _repository.getLocalCategories(userId);
        if (mounted && localCategories.isNotEmpty) {
          state = CategoryState(categories: localCategories, isLoading: true);
        }
      }

      final synced = await _repository.syncWithCloud(userId: userId);
      if (!mounted) return;
      state = CategoryState(categories: synced, isLoading: false);
    } catch (e, st) {
      AppLogger.warning(
        'Failed when loading categories',
        error: e,
        stackTrace: st,
        scope: 'category_provider',
      );
      if (!mounted) return;
      state = CategoryState(
        categories: state.categories,
        isLoading: false,
        error: "Failed when loading categories: $e",
      );
    }
  }

  Future<bool> createCategory(String name, String color, String icon) async {
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) return false;
      final success = await _repository.createCategory(
        name: name,
        colorHex: color,
        icon: icon,
        userId: userId,
      );
      if (success && mounted) {
        await loadCategories();
      }
      return success;
    } catch (e, st) {
      AppLogger.warning(
        'Error creating category',
        error: e,
        stackTrace: st,
        scope: 'category_provider',
      );
      return false;
    }
  }

  Future<bool> updateCategory({
    required String id,
    required String name,
    required String colorHex,
    required String icon,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) return false;
      final success = await _repository.updateCategory(
        id: id,
        name: name,
        colorHex: colorHex,
        icon: icon,
        userId: userId,
      );
      if (success && mounted) {
        await loadCategories();
      }
      return success;
    } catch (e, st) {
      AppLogger.warning(
        'Error updating category',
        error: e,
        stackTrace: st,
        scope: 'category_provider',
      );
      return false;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) return;
      await _repository.deleteCategory(id: id, userId: userId);
      if (mounted) {
        await loadCategories();
      }
    } catch (e, st) {
      AppLogger.warning(
        'Error deleting category',
        error: e,
        stackTrace: st,
        scope: 'category_provider',
      );
    }
  }
}

final categoryRepositoryProvider = Provider((ref) => CategoryRepository());

final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>(
  (ref) {
    ref.watch(authProvider.select((state) => state.user?.id));
    return CategoryNotifier(ref.watch(categoryRepositoryProvider), ref);
  },
);
