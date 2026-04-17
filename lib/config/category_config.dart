import 'package:flutter/material.dart';

class CategoryMeta {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryMeta({
    required this.name,
    required this.icon,
    required this.color,
  });
}

abstract final class CategoryConfig {
  static const List<CategoryMeta> all = [
    CategoryMeta(name: 'Health',       icon: Icons.favorite_rounded,       color: Color(0xFFFF6B6B)),
    CategoryMeta(name: 'Fitness',      icon: Icons.fitness_center_rounded,  color: Color(0xFFFF8C42)),
    CategoryMeta(name: 'Learning',     icon: Icons.menu_book_rounded,       color: Color(0xFF4DA6FF)),
    CategoryMeta(name: 'Finance',      icon: Icons.savings_rounded,         color: Color(0xFF00D4A0)),
    CategoryMeta(name: 'Mindfulness',  icon: Icons.self_improvement_rounded, color: Color(0xFF8B7FFF)),
    CategoryMeta(name: 'Creativity',   icon: Icons.palette_rounded,         color: Color(0xFFFF6B9D)),
    CategoryMeta(name: 'Social',       icon: Icons.people_rounded,          color: Color(0xFFFFB830)),
    CategoryMeta(name: 'Productivity', icon: Icons.rocket_launch_rounded,   color: Color(0xFF4DA6FF)),
    CategoryMeta(name: 'General',      icon: Icons.category_rounded,        color: Color(0xFFA3A3A3)),
    CategoryMeta(name: 'Other',        icon: Icons.more_horiz_rounded,      color: Color(0xFFA3A3A3)),
  ];

  static CategoryMeta forName(String name) {
    return all.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => all.last,
    );
  }

  /// All names including 'None' for the picker
  static List<String> get names => ['None', ...all.map((c) => c.name)];
}
