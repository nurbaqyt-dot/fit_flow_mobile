import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_colors.dart';
import '../models/user_model.dart';
import '../providers/profile_provider.dart';
import '../widgets/fit_button.dart';
import '../widgets/fit_card.dart';
import '../widgets/user_avatar.dart';
import 'screen_helpers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  final _picker = ImagePicker();
  XFile? _avatar;
  Uint8List? _preview;
  bool _hydrated = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _hydrate(FitUser? user) {
    if (_hydrated || user == null) return;
    _name.text = user.name;
    _username.text = user.username;
    _bio.text = user.bio;
    _hydrated = true;
  }

  Future<void> _pickAvatar() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 900,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() {
      _avatar = image;
      _preview = bytes;
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _username.text.trim().isEmpty) {
      showFitSnack(context, 'Name and username are required.', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            name: _name.text,
            username: _username.text,
            bio: _bio.text,
            avatar: _avatar,
          );
      if (mounted) showFitSnack(context, 'Profile updated.');
    } catch (error) {
      if (mounted) showFitSnack(context, '$error', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ScreenPadding(
        child: profile.when(
          data: (user) {
            _hydrate(user);
            return ListView(
              children: [
                FitCard(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: _preview == null
                            ? UserAvatar(
                                photoUrl: user?.photoUrl ?? '',
                                name: user?.name ?? 'Athlete',
                                size: 104,
                              )
                            : ClipOval(
                                child: Image.memory(
                                  _preview!,
                                  width: 104,
                                  height: 104,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _pickAvatar,
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Upload avatar'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _username,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _bio,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Bio'),
                ),
                const SizedBox(height: 24),
                FitButton(
                  label: 'Save',
                  icon: Icons.save,
                  onPressed: _save,
                  isLoading: _saving,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(
            'Profile could not load. $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}
