import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/app_logger.dart';
import '../models/category_model.dart';
import '../sources/api_client.dart';
import '../sources/database_service.dart';

class CategoryRepository {
  CategoryRepository({ApiClient? apiClient, DatabaseService? dbService})
    : _apiClient = apiClient ?? ApiClient(),
      _dbService = dbService ?? DatabaseService();

  final ApiClient _apiClient;
  final DatabaseService _dbService;
  static const int _pageSize = 100;

  Future<List<CategoryModel>> getLocalCategories(String userId) async {
    if (kIsWeb) return const [];
    return _dbService.getActiveCategories(userId);
  }

  Future<List<CategoryModel>> _fetchAllRemoteCategories() async {
    final result = <CategoryModel>[];
    var skip = 0;

    while (true) {
      final response = await _apiClient.dio.get(
        '/categories/',
        queryParameters: {
          'skip': skip,
          'limit': _pageSize,
          'include_deleted': true,
        },
      );
      if (response.statusCode != 200 || response.data == null) {
        break;
      }

      final raw = response.data;
      if (raw is! List || raw.isEmpty) {
        break;
      }
      result.addAll(
        raw
            .whereType<Map>()
            .map(
              (item) => CategoryModel.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList(),
      );

      if (raw.length < _pageSize) {
        break;
      }
      skip += _pageSize;
    }

    return result.where((category) => !category.isDeleted).toList();
  }

  bool _isRetryableFailure(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return true;
      }

      final status = error.response?.statusCode;
      if (status == null) {
        return true;
      }
      return status >= 500;
    }
    return false;
  }

  Future<void> _flushPendingOperations(String userId) async {
    if (kIsWeb) return;

    final operations = await _dbService.getPendingCategoryOperations(userId);
    for (final operation in operations) {
      final opId = operation['id'];
      if (opId is! int) {
        continue;
      }

      final opType = operation['op_type']?.toString() ?? '';
      final categoryId = operation['category_id']?.toString() ?? '';
      final payload = operation['payload'];

      try {
        switch (opType) {
          case 'create':
            await _apiClient.dio.post('/categories/', data: payload);
            await _dbService.removePendingCategoryOperation(opId);
            break;
          case 'update':
            await _apiClient.dio.patch(
              '/categories/$categoryId',
              data: payload,
            );
            await _dbService.removePendingCategoryOperation(opId);
            break;
          case 'delete':
            await _apiClient.dio.delete('/categories/$categoryId');
            await _dbService.removePendingCategoryOperation(opId);
            break;
          default:
            await _dbService.removePendingCategoryOperation(opId);
        }
      } catch (e) {
        if (e is DioException) {
          final status = e.response?.statusCode;
          if (status == 404) {
            await _dbService.removePendingCategoryOperation(opId);
            continue;
          }
        }
        if (_isRetryableFailure(e)) {
          break;
        }
        await _dbService.removePendingCategoryOperation(opId);
      }
    }
  }

  Future<List<CategoryModel>> syncWithCloud({required String userId}) async {
    try {
      await _flushPendingOperations(userId);
      final remote = await _fetchAllRemoteCategories();
      if (!kIsWeb) {
        await _dbService.upsertCategoriesBatch(remote);
      }
      return remote;
    } catch (e, st) {
      AppLogger.warning(
        'Category sync failed',
        error: e,
        stackTrace: st,
        scope: 'category_repo',
      );
      if (!kIsWeb) {
        return _dbService.getActiveCategories(userId);
      }
      return const [];
    }
  }

  Future<bool> createCategory({
    required String name,
    required String colorHex,
    required String icon,
    required String userId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    final now = DateTime.now().toUtc();
    final localId = const Uuid().v4();

    final localCategory = CategoryModel(
      id: localId,
      name: trimmedName,
      color: colorHex,
      icon: icon,
      userId: userId,
      updatedAt: now,
      isDeleted: false,
    );

    if (kIsWeb) {
      final response = await _apiClient.dio.post(
        '/categories/',
        data: {'name': trimmedName, 'color_hex': colorHex, 'icon': icon},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    }

    await _dbService.upsertCategory(localCategory);
    await _dbService.enqueueCategoryOperation(
      opType: 'create',
      categoryId: localId,
      userId: userId,
      payload: {
        'id': localId,
        'name': trimmedName,
        'color_hex': colorHex,
        'icon': icon,
      },
    );
    return true;
  }

  Future<bool> updateCategory({
    required String id,
    required String name,
    required String colorHex,
    required String icon,
    required String userId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    if (kIsWeb) {
      final response = await _apiClient.dio.patch(
        '/categories/$id',
        data: {'name': trimmedName, 'color_hex': colorHex, 'icon': icon},
      );
      return response.statusCode == 200;
    }

    final localCategories = await _dbService.getActiveCategories(userId);
    final existing = localCategories.firstWhere(
      (category) => category.id == id,
      orElse: () => CategoryModel(
        id: id,
        name: trimmedName,
        color: colorHex,
        icon: icon,
        userId: userId,
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    final updated = existing.copyWith(
      name: trimmedName,
      color: colorHex,
      icon: icon,
      updatedAt: DateTime.now().toUtc(),
    );
    await _dbService.upsertCategory(updated);
    await _dbService.enqueueCategoryOperation(
      opType: 'update',
      categoryId: id,
      userId: userId,
      payload: {'name': trimmedName, 'color_hex': colorHex, 'icon': icon},
    );
    return true;
  }

  Future<void> deleteCategory({
    required String id,
    required String userId,
  }) async {
    if (kIsWeb) {
      await _apiClient.dio.delete('/categories/$id');
      return;
    }

    await _dbService.deleteCategoryLocal(id, userId);
    await _dbService.enqueueCategoryOperation(
      opType: 'delete',
      categoryId: id,
      userId: userId,
      payload: const {},
    );
  }
}
