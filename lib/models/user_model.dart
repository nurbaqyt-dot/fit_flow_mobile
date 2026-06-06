import 'package:cloud_firestore/cloud_firestore.dart';

class FitUser {
  const FitUser({
    required this.uid,
    required this.name,
    required this.username,
    required this.bio,
    required this.photoUrl,
    required this.level,
    required this.totalXp,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalWorkouts,
    required this.following,
    required this.achievements,
    required this.settings,
  });

  factory FitUser.empty(String uid) {
    return FitUser(
      uid: uid,
      name: 'FitFlow Athlete',
      username: 'athlete',
      bio: 'Building momentum one session at a time.',
      photoUrl: '',
      level: 1,
      totalXp: 0,
      currentStreak: 0,
      bestStreak: 0,
      totalWorkouts: 0,
      following: 0,
      achievements: const <String, bool>{},
      settings: const <String, dynamic>{},
    );
  }

  factory FitUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return FitUser.empty(doc.id);
    final achievements = Map<String, bool>.from(
      (data['achievements'] as Map<String, dynamic>? ?? <String, dynamic>{})
          .map((key, value) => MapEntry(key, value == true)),
    );
    return FitUser(
      uid: doc.id,
      name: data['name'] as String? ?? 'FitFlow Athlete',
      username: data['username'] as String? ?? 'athlete',
      bio: data['bio'] as String? ?? 'Building momentum one session at a time.',
      photoUrl: data['photoUrl'] as String? ?? '',
      level: data['level'] as int? ?? 1,
      totalXp: data['totalXp'] as int? ?? 0,
      currentStreak: data['currentStreak'] as int? ?? 0,
      bestStreak: data['bestStreak'] as int? ?? 0,
      totalWorkouts: data['totalWorkouts'] as int? ?? 0,
      following: data['following'] as int? ?? 0,
      achievements: achievements,
      settings: Map<String, dynamic>.from(
        data['settings'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }

  final String uid;
  final String name;
  final String username;
  final String bio;
  final String photoUrl;
  final int level;
  final int totalXp;
  final int currentStreak;
  final int bestStreak;
  final int totalWorkouts;
  final int following;
  final Map<String, bool> achievements;
  final Map<String, dynamic> settings;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'bio': bio,
      'photoUrl': photoUrl,
      'level': level,
      'totalXp': totalXp,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'totalWorkouts': totalWorkouts,
      'following': following,
      'achievements': achievements,
      'settings': settings,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
