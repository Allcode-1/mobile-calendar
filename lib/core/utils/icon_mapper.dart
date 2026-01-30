import 'package:flutter/material.dart';

class IconMapper {
  static const Map<String, IconData> data = {
    'home': Icons.home_filled,
    'work': Icons.work,
    'school': Icons.school,
    'shopping': Icons.shopping_bag,
    'fitness': Icons.fitness_center,
    'travel': Icons.flight_takeoff,
    'food': Icons.restaurant,
    'health': Icons.favorite,
    'fun': Icons.sports_esports,
    'money': Icons.payments,
  };

  static IconData getIcon(String? name) {
    return data[name] ?? Icons.folder_rounded;
  }

  static List<String> get allNames => data.keys.toList();
}
