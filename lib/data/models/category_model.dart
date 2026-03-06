import 'package:flutter/material.dart';
import '../../core/utils/app_logger.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? color;
  final String? icon;
  final String userId;
  final DateTime updatedAt;
  final bool isDeleted;

  CategoryModel({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    required this.userId,
    required this.updatedAt,
    this.isDeleted = false,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    String? userId,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Color get flutterColor {
    if (color == null || color!.isEmpty) return Colors.grey;
    try {
      String hexCode = color!.trim().toUpperCase();
      if (hexCode.startsWith('#')) {
        hexCode = hexCode.substring(1);
      }
      if (hexCode.length == 6) {
        hexCode = 'FF$hexCode';
      }
      return Color(int.parse(hexCode, radix: 16));
    } catch (e) {
      AppLogger.warning(
        "Category color parsing failed: '$color'",
        error: e,
        scope: 'category_model',
      );
      return Colors.blue;
    }
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) {
        return DateTime.now();
      }
      try {
        return DateTime.parse(value.toString()).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }

    bool parseDeleted(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        final normalized = value.toLowerCase().trim();
        return normalized == '1' || normalized == 'true';
      }
      return false;
    }

    return CategoryModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      color: (json['color_hex'] ?? json['color'])?.toString(),
      icon: json['icon']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      updatedAt: parseDate(json['updated_at']),
      isDeleted: parseDeleted(json['is_deleted']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'color_hex': color,
      'icon': icon,
      'user_id': userId,
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  // for SQLite
  Map<String, dynamic> toDbMap() {
    final map = toJson();
    map.remove('color_hex');
    map['is_deleted'] = isDeleted ? 1 : 0;
    return map;
  }
}
