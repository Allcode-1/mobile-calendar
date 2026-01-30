import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sources/api_client.dart';
import '../data/models/category_model.dart';
import 'event_provider.dart';

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
  final ApiClient _apiClient = ApiClient();

  CategoryNotifier() : super(CategoryState()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    if (!mounted) return;
    state = CategoryState(categories: state.categories, isLoading: true);
    try {
      final response = await _apiClient.dio.get('/categories/');
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List data = response.data;
        final categories = data.map((e) => CategoryModel.fromJson(e)).toList();
        state = CategoryState(categories: categories, isLoading: false);
      } else {
        state = CategoryState(
          categories: state.categories,
          isLoading: false,
          error: "Server error: ${response.statusCode}",
        );
      }
    } catch (e) {
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
      final response = await _apiClient.dio.post(
        '/categories/',
        data: {'name': name, 'color_hex': color, 'icon': icon},
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          mounted) {
        await loadCategories();
        return true;
      }
      return false;
    } catch (e) {
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
      final response = await _apiClient.dio.patch(
        '/categories/$id',
        data: {'name': name, 'color_hex': colorHex, 'icon': icon},
      );
      if (response.statusCode == 200 && mounted) {
        await loadCategories();
        return true;
      }
      return false;
    } catch (e) {
      print("Error updating category: $e");
      return false;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final response = await _apiClient.dio.delete('/categories/$id');
      if ((response.statusCode == 200 || response.statusCode == 204) &&
          mounted) {
        await loadCategories();
      }
    } catch (e) {
      print("Error deleting category: $e");
    }
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>(
  (ref) {
    ref.watch(eventProvider);
    return CategoryNotifier();
  },
);
