import 'package:flutter/material.dart';

abstract final class AppConstants {
  static const appName = 'FitFlow';
  static const xpWorkout = 100;
  static const xpStreakBonus = 50;
  static const xpFeedPost = 20;
  static const xpPersonalRecord = 75;

  static const workoutTypes = <String>[
    'Strength',
    'Cardio',
    'HIIT',
    'Yoga',
    'Running',
    'Cycling',
  ];

  static const achievements = <String>[
    'First Workout',
    '7-Day Streak',
    '10 Workouts',
    'First Post',
    '50 Likes',
    'Personal Record',
  ];

  static String levelName(int xp) {
    if (xp >= 1000) return 'Elite';
    if (xp >= 500) return 'Pro';
    if (xp >= 200) return 'Athlete';
    return 'Beginner';
  }

  static int nextLevelXp(int xp) {
    if (xp < 200) return 200;
    if (xp < 500) return 500;
    if (xp < 1000) return 1000;
    return xp;
  }

  static IconData workoutIcon(String type) {
    switch (type.toLowerCase()) {
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.monitor_heart;
      case 'hiit':
        return Icons.flash_on;
      case 'yoga':
        return Icons.self_improvement;
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      default:
        return Icons.local_fire_department;
    }
  }
}
