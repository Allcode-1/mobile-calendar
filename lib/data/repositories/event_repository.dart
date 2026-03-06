import 'package:flutter/foundation.dart';
import '../../core/utils/app_logger.dart';

import '../models/event_model.dart';
import '../sources/api_client.dart';
import '../sources/database_service.dart';

class EventRepository {
  final ApiClient _apiClient = ApiClient();
  final DatabaseService _dbService = DatabaseService();

  Future<List<EventModel>> getEvents({required String userId}) async {
    try {
      if (kIsWeb) {
        return await syncWithCloud(userId: userId);
      }
      return await _dbService.getActiveEvents(userId);
    } catch (e) {
      AppLogger.warning('Failed to load events', error: e, scope: 'event_repo');
      return [];
    }
  }

  int _normalizePriority(dynamic value) {
    if (value is int && value >= 1 && value <= 3) {
      return value;
    }
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'low') return 1;
      if (normalized == 'high') return 3;
      if (normalized == 'medium') return 2;
      final asInt = int.tryParse(normalized);
      if (asInt != null && asInt >= 1 && asInt <= 3) return asInt;
    }
    return 2;
  }

  Map<String, dynamic> _normalizeApiUpdates(Map<String, dynamic> updates) {
    final apiUpdates = <String, dynamic>{};

    updates.forEach((key, value) {
      if (key == 'id' || key == 'user_id' || key == 'updated_at') {
        return;
      }
      if (key == 'isCompleted') {
        apiUpdates['is_completed'] = value;
      } else if (key == 'categoryId') {
        apiUpdates['category_id'] = value;
      } else if (key == 'startTime') {
        apiUpdates['start_at'] = value is DateTime
            ? value.toUtc().toIso8601String()
            : value;
      } else if (key == 'endTime') {
        apiUpdates['end_at'] = value is DateTime
            ? value.toUtc().toIso8601String()
            : value;
      } else if (key == 'reminderMinutes') {
        apiUpdates['remind_before'] = value;
      } else if (key == 'priority') {
        apiUpdates['priority'] = _normalizePriority(value);
      } else {
        apiUpdates[key] = value;
      }
    });

    return apiUpdates;
  }

  Future<void> addEvent(EventModel event, {required String userId}) async {
    final payload = event.copyWith(updatedAt: DateTime.now().toUtc());

    if (kIsWeb) {
      await _apiClient.dio.post(
        '/events/',
        data: payload.toJson(includeId: true),
      );
      return;
    }

    await _dbService.upsertEvent(payload);
  }

  Future<void> updateEvent(
    String id,
    Map<String, dynamic> updates, {
    required String userId,
  }) async {
    final apiUpdates = _normalizeApiUpdates(updates);

    if (kIsWeb) {
      await _apiClient.dio.patch('/events/$id', data: apiUpdates);
      return;
    }

    await _dbService.updateEventFields(id, apiUpdates, userId);
  }

  Future<void> deleteEvent(String id, {required String userId}) async {
    if (kIsWeb) {
      await _apiClient.dio.delete('/events/$id');
      return;
    }

    await _dbService.softDeleteEvent(id, userId);
  }

  Future<List<EventModel>> _fetchAllRemoteEvents({int pageSize = 200}) async {
    final merged = <EventModel>[];
    var skip = 0;

    while (true) {
      final response = await _apiClient.dio.get(
        '/events/',
        queryParameters: {'skip': skip, 'limit': pageSize},
      );
      if (response.statusCode != 200 || response.data == null) {
        break;
      }

      final raw = response.data;
      if (raw is! List || raw.isEmpty) {
        break;
      }

      merged.addAll(
        raw
            .whereType<Map>()
            .map(
              (e) => EventModel.fromJson(
                e.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList(),
      );
      if (raw.length < pageSize) {
        break;
      }
      skip += pageSize;
    }

    return merged;
  }

  Future<List<EventModel>> syncWithCloud({required String userId}) async {
    try {
      if (kIsWeb) {
        return await _fetchAllRemoteEvents();
      }

      final localEvents = await _dbService.getAllEventsForSync(userId);
      final payload = {
        'events': localEvents
            .map((event) => event.toJson(includeId: true))
            .toList(),
      };

      final response = await _apiClient.dio.post('/events/sync', data: payload);
      if (response.statusCode != 200 || response.data == null) {
        return await _dbService.getActiveEvents(userId);
      }

      final serverData = response.data;
      if (serverData is! List) {
        return await _dbService.getActiveEvents(userId);
      }

      final mergedEvents = serverData
          .whereType<Map>()
          .map(
            (e) => EventModel.fromJson(
              e.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
      await _dbService.upsertEventsBatch(mergedEvents);

      return mergedEvents.where((event) => !event.isDeleted).toList();
    } catch (e) {
      AppLogger.warning('Events sync failed', error: e, scope: 'event_repo');
      if (!kIsWeb) {
        return await _dbService.getActiveEvents(userId);
      }
      return [];
    }
  }

  Future<void> clearLocalData() async {
    if (!kIsWeb) {
      await _dbService.clearAllData();
    }
  }

  Future<void> clearLocalDataForUser(String userId) async {
    if (!kIsWeb) {
      await _dbService.clearUserData(userId);
    }
  }

  List<EventModel> _filterByCategory(
    List<EventModel> events, {
    String? categoryId,
  }) {
    if (categoryId == null) {
      return events;
    }
    final normalizedCategory = categoryId == 'uncategorized'
        ? null
        : categoryId;
    return events
        .where((event) => event.categoryId == normalizedCategory)
        .toList();
  }

  Future<List<EventModel>> getEventsFiltered({
    required String userId,
    String? categoryId,
  }) async {
    try {
      if (kIsWeb) {
        final events = await syncWithCloud(userId: userId);
        return _filterByCategory(events, categoryId: categoryId);
      }

      final localEvents = await _dbService.getActiveEvents(userId);
      return _filterByCategory(localEvents, categoryId: categoryId);
    } catch (e) {
      AppLogger.warning(
        'Failed to load filtered events',
        error: e,
        scope: 'event_repo',
      );
      if (!kIsWeb) {
        final localEvents = await _dbService.getActiveEvents(userId);
        return _filterByCategory(localEvents, categoryId: categoryId);
      }
      return [];
    }
  }
}
