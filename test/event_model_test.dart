import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_calendar/data/models/event_model.dart';

void main() {
  test('EventModel normalizes string priority into numeric value', () {
    final model = EventModel.fromJson({
      'id': 'evt-1',
      'title': 'Task',
      'user_id': 'user-1',
      'updated_at': DateTime.utc(2026, 1, 1).toIso8601String(),
      'priority': 'high',
    });

    expect(model.priority, 3);
  });

  test('EventModel writes database map with backend-compatible keys', () {
    final model = EventModel(
      id: 'evt-1',
      title: 'Task',
      userId: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      startTime: DateTime.utc(2026, 1, 2, 10),
      endTime: DateTime.utc(2026, 1, 2, 11),
      priority: 2,
      reminderMinutes: 15,
    );

    final dbMap = model.toDbMap();
    expect(dbMap.containsKey('start_at'), isTrue);
    expect(dbMap.containsKey('end_at'), isTrue);
    expect(dbMap['priority'], 2);
    expect(dbMap['remind_before'], 15);
  });

  test('EventModel parses boolean and reminder values from strings', () {
    final model = EventModel.fromJson({
      'id': 'evt-2',
      'title': 'Task',
      'user_id': 'user-1',
      'updated_at': DateTime.utc(2026, 1, 1).toIso8601String(),
      'is_completed': 'true',
      'is_deleted': '0',
      'remind_before': '30',
    });

    expect(model.isCompleted, isTrue);
    expect(model.isDeleted, isFalse);
    expect(model.reminderMinutes, 30);
  });
}
