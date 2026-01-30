import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_calendar/logic/auth_provider.dart';
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

  EventNotifier(this._repository) : super(EventState()) {
    refreshEvents();
  }

  Future<void> refreshEvents() async {
    print("Loading events (Web: $kIsWeb)...");
    state = EventState(events: state.events, isLoading: true);
    try {
      final remoteEvents = await _repository.syncWithCloud();
      if (kIsWeb) {
        state = EventState(events: remoteEvents, isLoading: false);
      } else {
        final local = await _repository.getEvents();
        state = EventState(events: local, isLoading: false);
      }
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
      await _repository.addEvent(event);
      await refreshEvents();
    } catch (e) {
      state = EventState(events: state.events, error: e.toString());
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _repository.deleteEvent(id);
      await refreshEvents();
    } catch (e) {
      print("Error deleting event: $e");
    }
  }

  Future<void> toggleComplete(EventModel event) async {
    try {
      final bool newStatus = !event.isCompleted;
      await _repository.updateEvent(event.id, {'is_completed': newStatus});
      await refreshEvents();
    } catch (e) {
      print("Error toggling completion: $e");
    }
  }

  Future<void> updateEventTitle(String id, String newTitle) async {
    if (newTitle.trim().isEmpty) return;
    try {
      await _repository.updateEvent(id, {'title': newTitle.trim()});
      await refreshEvents();
    } catch (e) {
      print("Error updating title: $e");
    }
  }

  Future<void> updateEventFull(EventModel event) async {
    try {
      await _repository.updateEvent(event.id, event.toJson());

      await refreshEvents();
    } catch (e) {
      print("Error updating full event: $e");
      state = EventState(events: state.events, error: e.toString());
    }
  }
}

final eventRepositoryProvider = Provider((ref) => EventRepository());

final eventProvider = StateNotifierProvider<EventNotifier, EventState>((ref) {
  ref.watch(authProvider.select((s) => s.user?.id));
  return EventNotifier(ref.watch(eventRepositoryProvider));
});
