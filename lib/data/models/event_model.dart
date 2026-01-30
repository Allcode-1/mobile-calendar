class EventModel {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? categoryId;
  final String userId;
  final DateTime updatedAt;
  final bool isDeleted;
  final dynamic priority;
  final int? reminderMinutes;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.startTime,
    this.endTime,
    this.categoryId,
    required this.userId,
    required this.updatedAt,
    this.isDeleted = false,
    this.priority = 'medium',
    this.reminderMinutes,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value == "") return null;
      try {
        return DateTime.parse(value.toString()).toLocal();
      } catch (e) {
        return null;
      }
    }

    return EventModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'No Title',
      description: json['description']?.toString(),
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1,
      startTime: parseDate(json['start_at']),
      endTime: parseDate(json['end_at']),
      categoryId: json['category_id']?.toString(),
      userId: json['user_id']?.toString() ?? 'unknown',
      updatedAt: parseDate(json['updated_at']) ?? DateTime.now(),
      isDeleted: json['is_deleted'] == true || json['is_deleted'] == 1,
      priority: json['priority'] ?? 'medium',
      reminderMinutes: json['remind_before'] != null
          ? int.tryParse(json['remind_before'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category_id': categoryId,
      'start_at': startTime?.toIso8601String(),
      'end_at': endTime?.toIso8601String(),
      'remind_before': reminderMinutes,
      'is_completed': isCompleted,
      'priority': priority,
      'is_deleted': isDeleted,
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted ? 1 : 0,
      'start_at': startTime?.toIso8601String(),
      'end_at': endTime?.toIso8601String(),
      'category_id': categoryId,
      'user_id': userId,
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'priority': priority.toString(),
      'reminder_minutes': reminderMinutes,
    };
  }
}
