import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/post_model.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

final currentUserProvider = StreamProvider<FitUser?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(authUser.uid)
      .snapshots()
      .map((doc) => doc.exists ? FitUser.fromDoc(doc) : null);
});

final userByIdProvider = StreamProvider.family<FitUser?, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? FitUser.fromDoc(doc) : null);
});

final notificationsProvider = StreamProvider<List<NotificationItem>>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream.value(const <NotificationItem>[]);
  return ref
      .watch(firestoreProvider)
      .collection('notifications')
      .doc(authUser.uid)
      .collection('items')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map(NotificationItem.fromDoc).toList(growable: false),
      );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

class ProfileRepository {
  ProfileRepository({
    required this.auth,
    required this.firestore,
    required this.storage,
  });

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  Future<void> updateProfile({
    required String name,
    required String username,
    required String bio,
    XFile? avatar,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    var photoUrl = user.photoURL ?? '';
    if (avatar != null) {
      photoUrl = await _uploadAvatar(user.uid, avatar);
      await user.updatePhotoURL(photoUrl);
    }
    await user.updateDisplayName(name.trim());
    await firestore.collection('users').doc(user.uid).update({
      'name': name.trim(),
      'username': username.trim(),
      'bio': bio.trim(),
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final user = auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    await firestore.collection('users').doc(user.uid).update({
      'settings': settings,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markNotificationRead(String id) async {
    final user = auth.currentUser;
    if (user == null) return;
    await firestore
        .collection('notifications')
        .doc(user.uid)
        .collection('items')
        .doc(id)
        .update({'read': true});
  }

  Future<void> deleteAccount() async {
    final user = auth.currentUser;
    if (user == null) return;
    await firestore.collection('users').doc(user.uid).delete();
    await user.delete();
  }

  Future<String> _uploadAvatar(String uid, XFile avatar) async {
    final Uint8List bytes = await avatar.readAsBytes();
    final ref = storage.ref('profile_photos/$uid/avatar.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: avatar.mimeType));
    return ref.getDownloadURL();
  }
}
