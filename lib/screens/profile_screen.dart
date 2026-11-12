import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:kowopay/services/storage_service.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/utils/rate_limiter.dart';
import 'package:kowopay/utils/secure_logger.dart';
import 'package:kowopay/utils/validators.dart';
import 'package:kowopay/widgets/app_surfaces.dart';
import 'package:kowopay/widgets/user_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _email = '';
  String? _photoUrl;
  bool _isEditing = false;
  bool _isLoading = false;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final User? user = ref.read(authServiceProvider).currentUser;
    if (user == null || !mounted) return;
    _email = user.email ?? '';
    try {
      final Map<String, dynamic>? data =
          await ref.read(databaseServiceProvider).getUserOnce(user.uid);
      if (mounted && data != null) {
        setState(() {
          _nameController.text = (data['name'] as String?) ??
              (user.displayName ?? '');
          _phoneController.text = (data['phone'] as String?) ?? '';
          _photoUrl = data['photoUrl'] as String?;
        });
      }
    } catch (e) {
      SecureLog.error('Profile load', e);
    }
  }

  Future<void> _pickImage() async {
    if (!RateLimiter.allow('pick-image', const Duration(seconds: 1))) return;
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked == null) return;

    final Uint8List bytes = await picked.readAsBytes();
    final String? validationError = ImageFileValidator.validate(bytes);
    if (!mounted) return;
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() {
      _imageBytes = bytes;
      _isEditing = true;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!RateLimiter.allow('save-profile', const Duration(seconds: 2))) return;

    setState(() => _isLoading = true);
    try {
      final User? user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      String? newPhotoUrl;
      if (_imageBytes != null) {
        newPhotoUrl = await ref
            .read(storageServiceProvider)
            .uploadProfileImage(_imageBytes!, user.uid);
      }

      await ref.read(databaseServiceProvider).updateProfile(
            uid: user.uid,
            name: InputSanitizer.cleanText(_nameController.text, maxLength: 80),
            phone: InputSanitizer.cleanPhone(_phoneController.text),
            photoUrl: newPhotoUrl,
          );

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _imageBytes = null;
        if (newPhotoUrl != null) _photoUrl = newPhotoUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      SecureLog.error('Profile save', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile update failed. Please try again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = ref.watch(authStateProvider).valueOrNull;

    return CinematicScaffold(
      title: 'My profile',
      actions: [
        IconButton(
          tooltip: _isEditing ? 'Save' : 'Edit',
          icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_outlined),
          onPressed: _isLoading
              ? null
              : () {
                  if (_isEditing) {
                    _saveProfile();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
        ),
      ],
      body: user == null
          ? const Center(child: Text('Please sign in again.'))
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _isEditing ? _pickImage : null,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          _imageBytes != null
                              ? CircleAvatar(
                                  radius: 54,
                                  backgroundColor: AppColors.lilac,
                                  backgroundImage: MemoryImage(_imageBytes!),
                                )
                              : UserAvatar(
                                  photoUrl: _photoUrl,
                                  email: _email,
                                  radius: 54,
                                ),
                          if (_isEditing)
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.buttonGradient,
                                border: Border.all(
                                  color: AppColors.white,
                                  width: 2.5,
                                ),
                              ),
                              child: const Icon(Icons.camera_alt_outlined,
                                  size: 15, color: AppColors.white),
                            ),
                        ],
                      ),
                    ),
                    if (_isEditing)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'Tap the photo to change it',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    GlassCard(
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: _email,
                            readOnly: true,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              suffixIcon: Icon(Icons.verified_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('nameField'),
                            controller: _nameController,
                            enabled: _isEditing,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: Validators.fullName,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('phoneField'),
                            controller: _phoneController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: Validators.phone,
                          ),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
