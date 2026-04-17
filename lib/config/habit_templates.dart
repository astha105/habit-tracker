import 'package:flutter/material.dart';

class HabitTemplate {
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final Color color;
  final int targetDays;

  const HabitTemplate({
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.targetDays,
  });
}

class TemplatePack {
  final String name;
  final String description;
  final String emoji;
  final Color color;
  final List<HabitTemplate> habits;

  const TemplatePack({
    required this.name,
    required this.description,
    required this.emoji,
    required this.color,
    required this.habits,
  });
}

abstract final class HabitTemplates {
  static const List<TemplatePack> packs = [
    TemplatePack(
      name: 'Morning Routine',
      description: 'Start every day with energy and intention',
      emoji: '☀️',
      color: Color(0xFFFFB830),
      habits: [
        HabitTemplate(title: 'Drink a glass of water', description: 'Hydrate first thing in the morning', category: 'Health', icon: Icons.local_drink_outlined, color: Color(0xFF4DA6FF), targetDays: 30),
        HabitTemplate(title: 'Plan my day', description: 'Write down top 3 priorities each morning', category: 'Productivity', icon: Icons.edit_note_rounded, color: Color(0xFF8B7FFF), targetDays: 30),
        HabitTemplate(title: 'Morning stretch', description: '5 minutes of light stretching', category: 'Fitness', icon: Icons.accessibility_new_outlined, color: Color(0xFFFF8C42), targetDays: 21),
        HabitTemplate(title: 'No phone first 30 min', description: 'Start the day screen-free', category: 'Mindfulness', icon: Icons.phone_disabled_outlined, color: Color(0xFF00D4A0), targetDays: 21),
      ],
    ),
    TemplatePack(
      name: 'Fitness Starter',
      description: 'Build a consistent movement habit',
      emoji: '💪',
      color: Color(0xFFFF6B47),
      habits: [
        HabitTemplate(title: 'Daily walk', description: '20+ minutes of walking', category: 'Fitness', icon: Icons.directions_walk_outlined, color: Color(0xFF00D4A0), targetDays: 30),
        HabitTemplate(title: 'Push-ups', description: 'At least 10 push-ups a day', category: 'Fitness', icon: Icons.fitness_center_outlined, color: Color(0xFFFF6B47), targetDays: 30),
        HabitTemplate(title: 'Workout session', description: 'Any workout for 30+ minutes', category: 'Fitness', icon: Icons.sports_gymnastics, color: Color(0xFFFF8C42), targetDays: 21),
        HabitTemplate(title: 'Track water intake', description: 'Log 8 glasses of water', category: 'Health', icon: Icons.water_drop_outlined, color: Color(0xFF4DA6FF), targetDays: 30),
      ],
    ),
    TemplatePack(
      name: 'Sleep Hygiene',
      description: 'Unlock better rest and recovery',
      emoji: '🌙',
      color: Color(0xFF8B7FFF),
      habits: [
        HabitTemplate(title: 'No screens 1hr before bed', description: 'Wind down without blue light', category: 'Health', icon: Icons.bedtime_outlined, color: Color(0xFF8B7FFF), targetDays: 21),
        HabitTemplate(title: 'Consistent sleep time', description: 'Go to bed at the same time nightly', category: 'Health', icon: Icons.schedule_outlined, color: Color(0xFF4DA6FF), targetDays: 30),
        HabitTemplate(title: 'Evening wind-down', description: '10-min journaling or reading', category: 'Mindfulness', icon: Icons.self_improvement_outlined, color: Color(0xFF00D4A0), targetDays: 21),
        HabitTemplate(title: 'No caffeine after 2pm', description: 'Avoid late caffeine', category: 'Health', icon: Icons.local_cafe_outlined, color: Color(0xFFFFB830), targetDays: 14),
      ],
    ),
    TemplatePack(
      name: 'Mindfulness',
      description: 'Reduce stress and sharpen focus',
      emoji: '🧘',
      color: Color(0xFF00D4A0),
      habits: [
        HabitTemplate(title: 'Meditate', description: '10 minutes of quiet meditation', category: 'Mindfulness', icon: Icons.self_improvement_outlined, color: Color(0xFF8B7FFF), targetDays: 30),
        HabitTemplate(title: 'Gratitude journaling', description: 'Write 3 things you are grateful for', category: 'Mindfulness', icon: Icons.menu_book_outlined, color: Color(0xFFFFB830), targetDays: 30),
        HabitTemplate(title: 'Deep breathing', description: '5 minutes of box breathing', category: 'Mindfulness', icon: Icons.air_outlined, color: Color(0xFF00D4A0), targetDays: 21),
        HabitTemplate(title: 'Digital detox hour', description: '1 hour screen-free each day', category: 'Mindfulness', icon: Icons.do_not_disturb_on_outlined, color: Color(0xFFFF6B47), targetDays: 14),
      ],
    ),
    TemplatePack(
      name: 'Learning',
      description: 'Grow your mind a little every day',
      emoji: '📚',
      color: Color(0xFF4DA6FF),
      habits: [
        HabitTemplate(title: 'Read 20 minutes', description: 'Any book or article', category: 'Learning', icon: Icons.menu_book_outlined, color: Color(0xFF4DA6FF), targetDays: 30),
        HabitTemplate(title: 'Learn one new thing', description: 'Watch a lecture, tutorial, or documentary', category: 'Learning', icon: Icons.lightbulb_outline, color: Color(0xFFFFB830), targetDays: 30),
        HabitTemplate(title: 'Practice a skill', description: '15+ minutes on a skill you are building', category: 'Learning', icon: Icons.psychology_outlined, color: Color(0xFF8B7FFF), targetDays: 21),
        HabitTemplate(title: 'Vocabulary word', description: 'Learn one new word daily', category: 'Learning', icon: Icons.translate_outlined, color: Color(0xFF00D4A0), targetDays: 30),
      ],
    ),
  ];
}
