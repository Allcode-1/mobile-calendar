import 'package:flutter/material.dart';

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
      debugPrint("🔴 Color parsing error '$color': $e");
      return Colors.blue;
    }
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      color: json['color_hex'] ?? json['color'],
      icon: json['icon'],
      userId: json['user_id']?.toString() ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      isDeleted: json['is_deleted'] is int
          ? json['is_deleted'] == 1
          : (json['is_deleted'] ?? false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'user_id': userId,
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  // for SQLite
  Map<String, dynamic> toDbMap() {
    final map = toJson();
    map['is_deleted'] = isDeleted ? 1 : 0;
    return map;
  }
}
