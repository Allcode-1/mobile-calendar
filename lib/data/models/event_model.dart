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
  final int priority;
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
    this.priority = 2,
    this.reminderMinutes,
  });

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? startTime,
    DateTime? endTime,
    String? categoryId,
    String? userId,
    DateTime? updatedAt,
    bool? isDeleted,
    int? priority,
    int? reminderMinutes,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      priority: priority ?? this.priority,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    );
  }

  static int _parsePriority(dynamic value) {
    if (value is int && value >= 1 && value <= 3) return value;
    if (value is double) {
      final asInt = value.toInt();
      if (asInt >= 1 && asInt <= 3) return asInt;
    }
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'low') return 1;
      if (normalized == 'medium') return 2;
      if (normalized == 'high') return 3;
      final asInt = int.tryParse(normalized);
      if (asInt != null && asInt >= 1 && asInt <= 3) return asInt;
    }
    return 2;
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value == "") return null;
      try {
        return DateTime.parse(value.toString()).toLocal();
      } catch (e) {
        return null;
      }
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        final normalized = value.toLowerCase().trim();
        return normalized == '1' || normalized == 'true';
      }
      return false;
    }

    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(value.toString());
    }

    return EventModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'No Title',
      description: json['description']?.toString(),
      isCompleted: parseBool(json['is_completed']),
      startTime: parseDate(json['start_at'] ?? json['start_time']),
      endTime: parseDate(json['end_at'] ?? json['end_time']),
      categoryId: json['category_id']?.toString(),
      userId: json['user_id']?.toString() ?? 'unknown',
      updatedAt: parseDate(json['updated_at']) ?? DateTime.now(),
      isDeleted: parseBool(json['is_deleted']),
      priority: _parsePriority(json['priority']),
      reminderMinutes: parseNullableInt(
        json['remind_before'] ?? json['reminder_minutes'],
      ),
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'category_id': categoryId,
      'start_at': startTime?.toUtc().toIso8601String(),
      'end_at': endTime?.toUtc().toIso8601String(),
      'is_completed': isCompleted,
      'priority': priority,
      'is_deleted': isDeleted,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };

    if (reminderMinutes != null) {
      map['remind_before'] = reminderMinutes;
    }

    if (includeId) {
      map['id'] = id;
    }

    return map;
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted ? 1 : 0,
      'start_at': startTime?.toUtc().toIso8601String(),
      'end_at': endTime?.toUtc().toIso8601String(),
      'category_id': categoryId,
      'user_id': userId,
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'priority': priority,
      'remind_before': reminderMinutes,
    };
  }
}
