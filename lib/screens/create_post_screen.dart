import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../providers/feed_provider.dart';
import '../widgets/fit_button.dart';
import '../widgets/fit_card.dart';
import 'screen_helpers.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _text = TextEditingController();
  final _picker = ImagePicker();
  XFile? _image;
  Uint8List? _preview;
  String _workoutType = 'Strength';
  bool _posting = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() {
      _image = image;
      _preview = bytes;
    });
  }

  Future<void> _post() async {
    if (_text.text.trim().isEmpty && _image == null) {
      showFitSnack(
        context,
        'Add a workout note or a photo before posting.',
        isError: true,
      );
      return;
    }
    setState(() => _posting = true);
    try {
      await ref
          .read(feedRepositoryProvider)
          .createPost(
            text: _text.text,
            workoutType: _workoutType,
            image: _image,
          );
      if (mounted) context.go('/feed');
    } catch (error) {
      if (mounted) showFitSnack(context, '$error', isError: true);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create post')),
      body: ScreenPadding(
        child: ListView(
          children: [
            FitCard(
              child: TextField(
                controller: _text,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'What did you crush today?',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_preview != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: Image.memory(_preview!, fit: BoxFit.cover),
                ),
              )
            else
              FitCard(
                onTap: _pickImage,
                child: const Row(
                  children: [
                    Icon(Icons.photo_library, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(child: Text('Pick image from gallery')),
                    Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ),
            if (_preview != null) ...[
              const SizedBox(height: 10),
              FitButton(
                label: 'Change Photo',
                icon: Icons.photo_library,
                onPressed: _pickImage,
                secondary: true,
              ),
            ],
            const SizedBox(height: 18),
            const Text(
              'Workout tag',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppConstants.workoutTypes.map((type) {
                return FilterChip(
                  label: Text(type),
                  selected: _workoutType == type,
                  onSelected: (_) => setState(() => _workoutType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            FitButton(
              label: 'Post',
              icon: Icons.send,
              onPressed: _post,
              isLoading: _posting,
            ),
          ],
        ),
      ),
    );
  }
}
