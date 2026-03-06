import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_calendar/logic/auth_provider.dart';
import '../core/utils/app_logger.dart';
import '../data/models/event_model.dart';
import '../data/repositories/event_repository.dart';

class EventState {
  final List<EventModel> events;
  final bool isLoading;
  final String? error;

  EventState({this.events = const [], this.isLoading = false, this.error});

  int get totalTasks => events.length;
  int get completedTasks => events.where((e) => e.isCompleted == true).length;
  double get progress => totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
}

class EventNotifier extends StateNotifier<EventState> {
  final EventRepository _repository;
  final Ref _ref;

  EventNotifier(this._repository, this._ref) : super(EventState()) {
    refreshEvents();
  }

  String? get _currentUserId => _ref.read(authProvider).user?.id;

  Future<void> refreshEvents() async {
    state = EventState(events: state.events, isLoading: true);

    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) {
        state = EventState(events: const [], isLoading: false);
        return;
      }

      if (kIsWeb) {
        final remoteEvents = await _repository.syncWithCloud(userId: userId);
        state = EventState(events: remoteEvents, isLoading: false);
        return;
      }

      final localEvents = await _repository.getEvents(userId: userId);
      state = EventState(events: localEvents, isLoading: false);

      final syncedEvents = await _repository.syncWithCloud(userId: userId);
      state = EventState(events: syncedEvents, isLoading: false);
    } catch (e) {
      state = EventState(
        events: state.events,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addEvent(EventModel event) async {
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) return;
      await _repository.addEvent(
        event.copyWith(userId: userId),
        userId: userId,
      );
      await refreshEvents();
    } catch (e) {
      state = EventState(events: state.events, error: e.toString());
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) return;
      await _repository.deleteEvent(id, userId: userId);
      await refreshEvents();
    } catch (e) {
      AppLogger.warning(
        'Error deleting event',
        error: e,
        scope: 'event_provider',
      );
    }
  }

  Future<void> toggleComplete(EventModel event) async {
    try {
      final bool newStatus = !event.isCompleted;
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) return;
      await _repository.updateEvent(event.id, {
        'is_completed': newStatus,
      }, userId: userId);
      await refreshEvents();
    } catch (e) {
      AppLogger.warning(
        'Error toggling completion',
        error: e,
        scope: 'event_provider',
      );
    }
  }

  Future<void> updateEventTitle(String id, String newTitle) async {
    if (newTitle.trim().isEmpty) return;
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) return;
      await _repository.updateEvent(id, {
        'title': newTitle.trim(),
      }, userId: userId);
      await refreshEvents();
    } catch (e) {
      AppLogger.warning(
        'Error updating title',
        error: e,
        scope: 'event_provider',
      );
    }
  }

  Future<void> updateEventFull(EventModel event) async {
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) return;
      await _repository.updateEvent(event.id, event.toJson(), userId: userId);

      await refreshEvents();
    } catch (e) {
      AppLogger.warning(
        'Error updating full event',
        error: e,
        scope: 'event_provider',
      );
      state = EventState(events: state.events, error: e.toString());
    }
  }
}

final eventRepositoryProvider = Provider((ref) => EventRepository());

final eventProvider = StateNotifierProvider<EventNotifier, EventState>((ref) {
  ref.watch(authProvider.select((s) => s.user?.id));
  return EventNotifier(ref.watch(eventRepositoryProvider), ref);
});
