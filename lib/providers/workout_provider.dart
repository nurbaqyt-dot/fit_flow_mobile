import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/constants/app_constants.dart';
import '../models/exercise_model.dart';
import '../models/workout_model.dart';
import 'auth_provider.dart';

final workoutCategoriesProvider = Provider<List<WorkoutCategory>>((ref) {
  return const [
    WorkoutCategory(
      type: 'Strength',
      name: 'Power Builder',
      description: 'Compound lifts and accessories for full-body strength.',
      estimatedCalories: 420,
      exercises: [
        ExerciseModel(name: 'Barbell squat', sets: 4, reps: 6, restSeconds: 75),
        ExerciseModel(name: 'Bench press', sets: 4, reps: 8, restSeconds: 75),
        ExerciseModel(
          name: 'Romanian deadlift',
          sets: 3,
          reps: 10,
          restSeconds: 60,
        ),
        ExerciseModel(name: 'Dumbbell row', sets: 3, reps: 12, restSeconds: 45),
      ],
    ),
    WorkoutCategory(
      type: 'Cardio',
      name: 'Heart Rate Climb',
      description: 'A steady cardio block built around smooth effort ramps.',
      estimatedCalories: 360,
      exercises: [
        ExerciseModel(name: 'Warm-up walk', sets: 1, reps: 8, restSeconds: 20),
        ExerciseModel(
          name: 'Zone 3 intervals',
          sets: 5,
          reps: 3,
          restSeconds: 45,
        ),
        ExerciseModel(name: 'Tempo push', sets: 3, reps: 2, restSeconds: 40),
        ExerciseModel(name: 'Cooldown walk', sets: 1, reps: 6, restSeconds: 20),
      ],
    ),
    WorkoutCategory(
      type: 'HIIT',
      name: 'Lime Sprint',
      description: 'Short, intense intervals for a fast metabolic hit.',
      estimatedCalories: 480,
      exercises: [
        ExerciseModel(name: 'Jump squats', sets: 4, reps: 15, restSeconds: 35),
        ExerciseModel(
          name: 'Mountain climbers',
          sets: 4,
          reps: 30,
          restSeconds: 30,
        ),
        ExerciseModel(name: 'Burpees', sets: 4, reps: 12, restSeconds: 45),
        ExerciseModel(
          name: 'Plank shoulder taps',
          sets: 3,
          reps: 24,
          restSeconds: 30,
        ),
      ],
    ),
    WorkoutCategory(
      type: 'Yoga',
      name: 'Mobility Flow',
      description: 'A strength-friendly mobility sequence for recovery days.',
      estimatedCalories: 190,
      exercises: [
        ExerciseModel(
          name: 'Sun salutations',
          sets: 3,
          reps: 5,
          restSeconds: 20,
        ),
        ExerciseModel(name: 'Warrior flow', sets: 3, reps: 6, restSeconds: 25),
        ExerciseModel(
          name: 'Pigeon stretch',
          sets: 2,
          reps: 4,
          restSeconds: 20,
        ),
        ExerciseModel(
          name: 'Breathing reset',
          sets: 1,
          reps: 5,
          restSeconds: 10,
        ),
      ],
    ),
    WorkoutCategory(
      type: 'Running',
      name: 'City Strides',
      description: 'A guided run with warm-up, tempo work, and cooldown.',
      estimatedCalories: 520,
      exercises: [
        ExerciseModel(name: 'Easy jog', sets: 1, reps: 10, restSeconds: 30),
        ExerciseModel(name: 'Tempo run', sets: 4, reps: 5, restSeconds: 60),
        ExerciseModel(name: 'Fast finish', sets: 3, reps: 1, restSeconds: 45),
        ExerciseModel(name: 'Cooldown jog', sets: 1, reps: 8, restSeconds: 30),
      ],
    ),
    WorkoutCategory(
      type: 'Cycling',
      name: 'Cadence Control',
      description: 'Cadence ladders and climbs for cycling endurance.',
      estimatedCalories: 460,
      exercises: [
        ExerciseModel(name: 'Spin warm-up', sets: 1, reps: 8, restSeconds: 20),
        ExerciseModel(
          name: 'Cadence ladder',
          sets: 5,
          reps: 2,
          restSeconds: 35,
        ),
        ExerciseModel(name: 'Seated climb', sets: 4, reps: 4, restSeconds: 50),
        ExerciseModel(name: 'Easy spin', sets: 1, reps: 7, restSeconds: 20),
      ],
    ),
  ];
});

final userWorkoutsProvider = StreamProvider<List<WorkoutModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const <WorkoutModel>[]);
  return _userWorkoutsQuery(ref.watch(firestoreProvider), user.uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(WorkoutModel.fromDoc).toList());
});

final recentWorkoutsProvider = StreamProvider<List<WorkoutModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const <WorkoutModel>[]);
  return _userWorkoutsQuery(ref.watch(firestoreProvider), user.uid)
      .limit(3)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(WorkoutModel.fromDoc).toList());
});

final workoutsForDayProvider =
    StreamProvider.family<List<WorkoutModel>, DateTime>((ref, date) {
      final user = ref.watch(authStateProvider).value;
      if (user == null) return Stream.value(const <WorkoutModel>[]);
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      return ref
          .watch(firestoreProvider)
          .collection('workouts')
          .where('userId', isEqualTo: user.uid)
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('completedAt', isLessThan: Timestamp.fromDate(end))
          .orderBy('completedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(WorkoutModel.fromDoc).toList());
    });

final historyFilterProvider = StateProvider<String>((ref) => 'All');
final selectedHistoryDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

Query<Map<String, dynamic>> _userWorkoutsQuery(
  FirebaseFirestore firestore,
  String uid,
) {
  return firestore
      .collection('workouts')
      .where('userId', isEqualTo: uid)
      .orderBy('completedAt', descending: true);
}

class WorkoutRepository {
  WorkoutRepository({required this.auth, required this.firestore});

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  Future<WorkoutResult> completeWorkout({
    required WorkoutCategory category,
    required int durationSeconds,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');

    final userRef = firestore.collection('users').doc(user.uid);
    final latestWorkout = await firestore
        .collection('workouts')
        .where('userId', isEqualTo: user.uid)
        .orderBy('completedAt', descending: true)
        .limit(1)
        .get();

    final previousCompletedAt = latestWorkout.docs.isEmpty
        ? null
        : WorkoutModel.fromDoc(latestWorkout.docs.first).completedAt;
    final userDoc = await userRef.get();
    final currentStreak = userDoc.data()?['currentStreak'] as int? ?? 0;
    final newStreak = _nextStreak(currentStreak, previousCompletedAt);
    final streakBonus = newStreak == 7 ? AppConstants.xpStreakBonus : 0;
    final xpEarned = AppConstants.xpWorkout + streakBonus;
    final calories = _scaledCalories(
      category.estimatedCalories,
      durationSeconds,
    );
    final completedAt = DateTime.now();
    final workout = WorkoutModel(
      id: '',
      userId: user.uid,
      type: category.type,
      name: category.name,
      durationSeconds: durationSeconds,
      caloriesBurned: calories,
      exercises: category.exercises,
      xpEarned: xpEarned,
      completedAt: completedAt,
    );

    final workoutRef = firestore.collection('workouts').doc();
    final totalXp = userDoc.data()?['totalXp'] as int? ?? 0;
    final totalWorkouts = userDoc.data()?['totalWorkouts'] as int? ?? 0;
    final bestStreak = userDoc.data()?['bestStreak'] as int? ?? 0;
    final achievements = Map<String, dynamic>.from(
      userDoc.data()?['achievements'] as Map<String, dynamic>? ??
          <String, dynamic>{},
    );
    achievements['First Workout'] = true;
    if (newStreak >= 7) achievements['7-Day Streak'] = true;
    if (totalWorkouts + 1 >= 10) achievements['10 Workouts'] = true;

    await firestore.runTransaction((transaction) async {
      transaction.set(workoutRef, workout.toMap());
      transaction.update(userRef, {
        'totalXp': totalXp + xpEarned,
        'level': _levelForXp(totalXp + xpEarned),
        'totalWorkouts': totalWorkouts + 1,
        'currentStreak': newStreak,
        'bestStreak': newStreak > bestStreak ? newStreak : bestStreak,
        'achievements': achievements,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return WorkoutResult(
      category: category,
      durationSeconds: durationSeconds,
      caloriesBurned: calories,
      xpEarned: xpEarned,
      exercisesDone: category.exercises.length,
    );
  }

  int _scaledCalories(int estimate, int seconds) {
    final minutes = seconds / 60;
    final scale = (minutes / 35).clamp(0.45, 1.35);
    return (estimate * scale).round();
  }

  int _nextStreak(int currentStreak, DateTime? previous) {
    if (previous == null) return 1;
    final today = DateTime.now();
    final startToday = DateTime(today.year, today.month, today.day);
    final previousDay = DateTime(previous.year, previous.month, previous.day);
    if (previousDay == startToday) {
      return currentStreak == 0 ? 1 : currentStreak;
    }
    if (previousDay == startToday.subtract(const Duration(days: 1))) {
      return currentStreak + 1;
    }
    return 1;
  }

  int _levelForXp(int xp) {
    if (xp >= 1000) return 4;
    if (xp >= 500) return 3;
    if (xp >= 200) return 2;
    return 1;
  }
}
