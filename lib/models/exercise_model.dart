class ExerciseModel {
  const ExerciseModel({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.maxWeightKg,
  });

  factory ExerciseModel.fromMap(Map<String, dynamic> data) {
    return ExerciseModel(
      name: data['name'] as String? ?? 'Training block',
      sets: data['sets'] as int? ?? 3,
      reps: data['reps'] as int? ?? 10,
      restSeconds: data['restSeconds'] as int? ?? 45,
      maxWeightKg: (data['maxWeightKg'] as num?)?.toDouble(),
    );
  }

  final String name;
  final int sets;
  final int reps;
  final int restSeconds;
  final double? maxWeightKg;

  Map<String, dynamic> toMap() {
    final data = {
      'name': name,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
    };
    if (maxWeightKg != null) data['maxWeightKg'] = maxWeightKg!;
    return data;
  }
}
