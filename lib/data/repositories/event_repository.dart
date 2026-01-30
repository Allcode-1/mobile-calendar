import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../sources/api_client.dart';
import '../sources/database_service.dart';

class EventRepository {
  final ApiClient _apiClient = ApiClient();
  final DatabaseService _dbService = DatabaseService();

  Future<List<EventModel>> getEvents() async {
    try {
      if (kIsWeb) {
        return await syncWithCloud();
      }
      return await _dbService.getActiveEvents();
    } catch (e) {
      debugPrint("Error in getEvents: $e");
      return [];
    }
  }

  Future<void> addEvent(EventModel event) async {
    if (kIsWeb) {
      try {
        await _apiClient.dio.post('/events/', data: event.toJson());
      } catch (e) {
        debugPrint("Web Add Event Error: $e");
      }
    } else {
      await _dbService.upsertEvent(event);
      try {
        await syncWithCloud();
      } catch (e) {
        debugPrint("Background sync failed: $e");
      }
    }
  }

  Future<void> updateEvent(String id, Map<String, dynamic> updates) async {
    final apiUpdates = <String, dynamic>{};
    updates.forEach((key, value) {
      if (key == 'isCompleted')
        apiUpdates['is_completed'] = value;
      else if (key == 'categoryId')
        apiUpdates['category_id'] = value;
      else
        apiUpdates[key] = value;
    });

    if (kIsWeb) {
      try {
        await _apiClient.dio.patch('/events/$id', data: apiUpdates);
        debugPrint("✅ Web Update Success: $id");
      } catch (e) {
        debugPrint("Web Update Error: $e");
      }
    } else {
      await _dbService.updateEventFields(id, updates);
      try {
        await _apiClient.dio.patch('/events/$id', data: apiUpdates);
      } catch (e) {
        debugPrint("Mobile cloud update failed: $e");
      }
    }
  }

  Future<void> deleteEvent(String id) async {
    if (kIsWeb) {
      try {
        await _apiClient.dio.delete('/events/$id');
      } catch (e) {
        debugPrint("Web Delete Error: $e");
      }
    } else {
      await _dbService.softDeleteEvent(id);
      try {
        await _apiClient.dio.delete('/events/$id');
      } catch (e) {
        debugPrint("Mobile cloud delete failed: $e");
      }
    }
  }

  Future<List<EventModel>> syncWithCloud() async {
    try {
      final response = await _apiClient.dio.get('/events/');
      if (response.statusCode == 200 && response.data != null) {
        final List data = response.data;
        return data.map((e) => EventModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Sync error: $e");
      return [];
    }
  }

  Future<void> clearLocalData() async {
    if (!kIsWeb) await _dbService.clearAllData();
  }

  Future<List<EventModel>> getEventsFiltered({String? categoryId}) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (categoryId != null) {
        queryParams['category_id'] = categoryId == 'uncategorized'
            ? null
            : categoryId;
      }

      final response = await _apiClient.dio.get(
        '/events/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final List data = response.data;
        final events = data.map((e) => EventModel.fromJson(e)).toList();

        if (!kIsWeb && categoryId == null) {
          for (var event in events) {
            await _dbService.upsertEvent(event);
          }
        }

        return events;
      }
      return [];
    } catch (e) {
      debugPrint("❌ Error in getEventsFiltered: $e");
      if (!kIsWeb) {
        final localEvents = await _dbService.getActiveEvents();
        if (categoryId != null) {
          return localEvents
              .where(
                (e) =>
                    e.categoryId ==
                    (categoryId == 'uncategorized' ? null : categoryId),
              )
              .toList();
        }
        return localEvents;
      }
      return [];
    }
  }
}
