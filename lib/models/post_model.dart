import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  const PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.text,
    required this.imageUrl,
    required this.workoutType,
    required this.likes,
    required this.createdAt,
  });

  factory PostModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return PostModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'FitFlow Athlete',
      userPhoto: data['userPhoto'] as String? ?? '',
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      workoutType: data['workoutType'] as String? ?? 'Strength',
      likes: List<String>.from(data['likes'] as List<dynamic>? ?? <dynamic>[]),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  final String id;
  final String userId;
  final String userName;
  final String userPhoto;
  final String text;
  final String imageUrl;
  final String workoutType;
  final List<String> likes;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'text': text,
      'imageUrl': imageUrl,
      'workoutType': workoutType,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.text,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  factory NotificationItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return NotificationItem(
      id: doc.id,
      text: data['text'] as String? ?? 'Your FitFlow update is ready.',
      type: data['type'] as String? ?? 'general',
      read: data['read'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  final String id;
  final String text;
  final String type;
  final bool read;
  final DateTime createdAt;
}
