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
    _loadProfile();
  }

  void _loadProfile() async {
     // Initial load logic if needed
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _isEditing = true; // Auto-enable editing when image is picked
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
       setState(() => _isLoading = true);
       try {
         final user = ref.read(authServiceProvider).currentUser;
         if (user != null) {
           String? newPhotoUrl;
           
           // Upload Image if selected
           if (_imageBytes != null) {
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting Image Upload...'), duration: Duration(seconds: 1)));
             newPhotoUrl = await ref.read(storageServiceProvider).uploadProfileImage(_imageBytes!, user.uid);
             print("Upload success, URL: $newPhotoUrl"); // Debug log
           }

           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving Profile Data...'), duration: Duration(seconds: 1)));
           
           await ref.read(databaseServiceProvider).updateProfile(
             uid: user.uid,
             name: _nameController.text.trim(),
             phone: _phoneController.text.trim(),
             photoUrl: newPhotoUrl,
           );
           
           setState(() {
             _isEditing = false;
             _imageBytes = null; // Clear local bytes to fallback to URL
           });
           
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated Successfully!')));
           }
         }
       } catch (e, stack) {
         print("Profile Save Error: $e\n$stack");
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), duration: const Duration(seconds: 5)));
       } finally {
         if (mounted) setState(() => _isLoading = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final db = ref.watch(databaseServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true),
          )
        ],
      ),
      body: StreamBuilder(
        stream: user != null ? db.getUserStream(user.uid) : null,
        builder: (context, snapshot) {
          if (user == null) return const Center(child: Text("User not logged in"));
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          // Populate fields
          if (snapshot.hasData && snapshot.data!.snapshot.value != null && !_isEditing && _nameController.text.isEmpty) {
             final data = snapshot.data!.snapshot.value as Map;
             _nameController.text = data['name'] ?? '';
             _phoneController.text = data['phone'] ?? '';
             _email = data['email'] ?? user.email ?? '';
             _photoUrl = data['photoUrl'];
          } else if (user.email != null && _email.isEmpty) {
             _email = user.email!;
          }

          // Use stream data for photo if no local override
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final data = snapshot.data!.snapshot.value as Map;
              if (data.containsKey('photoUrl')) {
                _photoUrl = data['photoUrl'];
              }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                   GestureDetector(
                     onTap: _isEditing ? _pickImage : null,
                     child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _imageBytes != null 
                          ? MemoryImage(_imageBytes!) 
                          : (_photoUrl != null ? NetworkImage(_photoUrl!) as ImageProvider : null),
                      child: (_imageBytes == null && _photoUrl == null)
                          ? const Icon(Icons.person, size: 50)
                          : null,
                     ),
                   ),
                   if (_isEditing) const Padding(padding: EdgeInsets.only(top: 8), child: Text("Tap image to change", style: TextStyle(fontSize: 12, color: Colors.deepPurple))),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: _email,
                    decoration: const InputDecoration(labelText: 'Email', filled: true),
                    readOnly: true,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                    enabled: _isEditing,
                    validator: (v) => v!.isEmpty ? 'Name required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 32),
                  if (_isLoading) const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}
