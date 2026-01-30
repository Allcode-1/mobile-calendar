import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../sources/api_client.dart';

class CategoryRepository {
  final ApiClient _apiClient = ApiClient();

  // get all categories from server
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.dio.get('/categories/');

      if (response.statusCode == 200 && response.data != null) {
        final List data = response.data;
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("❌ Error fetching categories: $e");
      return [];
    }
  }

  // create new one
  Future<CategoryModel?> createCategory({
    required String name,
    required String colorHex,
    required String icon,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/categories/',
        data: {'name': name, 'color_hex': colorHex, 'icon': icon},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CategoryModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error creating category: $e");
      return null;
    }
  }

  // delete category
  Future<bool> deleteCategory(String id) async {
    try {
      final response = await _apiClient.dio.delete('/categories/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Error deleting category: $e");
      return false;
    }
  }

  // update category
  Future<CategoryModel?> updateCategory(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      // create copy of map so we dont have to update og one
      final Map<String, dynamic> apiUpdates = Map.from(updates);

      // turn color to color_hex for api
      if (apiUpdates.containsKey('color')) {
        final colorValue = apiUpdates.remove('color');
        apiUpdates['color_hex'] = colorValue;
      }

      final response = await _apiClient.dio.patch(
        '/categories/$id',
        data: apiUpdates,
      );

      if (response.statusCode == 200) {
        return CategoryModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error updating category: $e");
      return null;
    }
  }
}
