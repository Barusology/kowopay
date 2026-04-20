import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _email = '';
  String? _photoUrl;
  bool _isEditing = false;
  bool _isLoading = false;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    // FIX: load initial profile data via addPostFrameCallback so we are NOT
    // mutating state during the first build phase.  The previous implementation
    // set _nameController.text inside the StreamBuilder builder, which caused
    // the "setState() called during build" exception.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    // FIX: both controllers were never disposed — memory leak on every
    // open/close of the profile screen.
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null || !mounted) return;

    try {
      final db = ref.read(databaseServiceProvider);
      final data = await db.getUserOnce(user.uid);
      if (mounted && data != null) {
        setState(() {
          _nameController.text = data['name'] as String? ?? '';
          _phoneController.text = data['phone'] as String? ?? '';
          _email = data['email'] as String? ?? user.email ?? '';
          _photoUrl = data['photoUrl'] as String?;
        });
      } else if (mounted) {
        setState(() => _email = user.email ?? '');
      }
    } catch (_) {
      if (mounted) setState(() => _email = user.email ?? '');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isEditing = true;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      String? newPhotoUrl;

      if (_imageBytes != null) {
        // FIX: debugPrint instead of print — print() is not stripped in release
        // builds and logs sensitive URLs to Android logcat (readable by other apps).
        debugPrint('[Profile] Starting image upload…');
        newPhotoUrl = await ref
            .read(storageServiceProvider)
            .uploadProfileImage(_imageBytes!, user.uid);
        debugPrint('[Profile] Upload complete');
      }

      await ref.read(databaseServiceProvider).updateProfile(
            uid: user.uid,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            photoUrl: newPhotoUrl,
          );

      if (mounted) {
        setState(() {
          _isEditing = false;
          _imageBytes = null;
          if (newPhotoUrl != null) _photoUrl = newPhotoUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stack) {
      // FIX: debugPrint instead of print — never log full stack traces with
      // print(); use debugPrint which is automatically suppressed in release.
      debugPrint('[Profile] Save error: $e\n$stack');
      if (mounted) {
        // FIX: friendly error message — the original code showed `Text('Failed: $e')`
        // which leaks internal exception details to the user.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile update failed. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
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
      ),
      body: user == null
          ? const Center(child: Text('User not logged in'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile photo
                    GestureDetector(
                      onTap: _isEditing ? _pickImage : null,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _imageBytes != null
                                ? MemoryImage(_imageBytes!)
                                : (_photoUrl != null
                                    ? NetworkImage(_photoUrl!)
                                        as ImageProvider
                                    : null),
                            child:
                                (_imageBytes == null && _photoUrl == null)
                                    ? const Icon(Icons.person, size: 50)
                                    : null,
                          ),
                          if (_isEditing)
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.deepPurple,
                              child: const Icon(Icons.camera_alt,
                                  size: 14, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                    if (_isEditing)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Tap to change photo',
                          style: TextStyle(
                              fontSize: 12, color: Colors.deepPurple),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Email (read-only)
                    TextFormField(
                      initialValue: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // Full name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      enabled: _isEditing,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Name is required'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 32),

                    if (_isLoading) const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
    );
  }
}
