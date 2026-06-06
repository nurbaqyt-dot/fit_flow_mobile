import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_constants.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';
import 'profile_provider.dart';

final feedPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('feed')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(PostModel.fromDoc).toList());
});

final latestFeedPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('feed')
      .orderBy('createdAt', descending: true)
      .limit(3)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(PostModel.fromDoc).toList());
});

final myPostsProvider = StreamProvider<List<PostModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const <PostModel>[]);
  return ref
      .watch(firestoreProvider)
      .collection('feed')
      .where('userId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(PostModel.fromDoc).toList());
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
    currentUser: () => ref.read(currentUserProvider).value,
  );
});

class FeedRepository {
  FeedRepository({
    required this.auth,
    required this.firestore,
    required this.storage,
    required this.currentUser,
  });

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final FitUser? Function() currentUser;

  Future<void> createPost({
    required String text,
    required String workoutType,
    XFile? image,
  }) async {
    final authUser = auth.currentUser;
    if (authUser == null) throw StateError('You must be signed in.');
    final profile = currentUser();
    final imageUrl = image == null
        ? ''
        : await _uploadPostImage(authUser.uid, image);
    final postRef = firestore.collection('feed').doc();
    final userRef = firestore.collection('users').doc(authUser.uid);
    final userDoc = await userRef.get();
    final totalXp = userDoc.data()?['totalXp'] as int? ?? 0;
    final achievements = Map<String, dynamic>.from(
      userDoc.data()?['achievements'] as Map<String, dynamic>? ??
          <String, dynamic>{},
    )..['First Post'] = true;

    await firestore.runTransaction((transaction) async {
      transaction.set(postRef, {
        'userId': authUser.uid,
        'userName': profile?.name ?? authUser.displayName ?? 'FitFlow Athlete',
        'userPhoto': profile?.photoUrl ?? authUser.photoURL ?? '',
        'text': text.trim(),
        'imageUrl': imageUrl,
        'workoutType': workoutType,
        'likes': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(userRef, {
        'totalXp': totalXp + AppConstants.xpFeedPost,
        'level': _levelForXp(totalXp + AppConstants.xpFeedPost),
        'achievements': achievements,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> toggleLike(PostModel post) async {
    final user = auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    final postRef = firestore.collection('feed').doc(post.id);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      final likes = List<String>.from(
        snapshot.data()?['likes'] as List<dynamic>? ?? <dynamic>[],
      );
      if (likes.contains(user.uid)) {
        likes.remove(user.uid);
      } else {
        likes.add(user.uid);
      }
      transaction.update(postRef, {'likes': likes});
      if (likes.length >= 50) {
        transaction.update(firestore.collection('users').doc(post.userId), {
          'achievements.50 Likes': true,
        });
      }
    });
  }

  Future<String> _uploadPostImage(String uid, XFile image) async {
    final Uint8List bytes = await image.readAsBytes();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final ref = storage.ref('workout_images/$uid/$stamp.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: image.mimeType));
    return ref.getDownloadURL();
  }

  int _levelForXp(int xp) {
    if (xp >= 1000) return 4;
    if (xp >= 500) return 3;
    if (xp >= 200) return 2;
    return 1;
  }
}
