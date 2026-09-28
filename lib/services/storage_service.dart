import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  StorageService({FirebaseStorage? storage, FirebaseAuth? auth})
    : _storage = storage ?? FirebaseStorage.instance,
      _auth = auth ?? FirebaseAuth.instance;

  static const int maxProfileImageBytes = 5 * 1024 * 1024;

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  Future<String> uploadProfileImage(Uint8List fileBytes) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Authentication is required.');
    validateProfileImageBytes(fileBytes);

    try {
      final ref = _storage
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');
      await ref.putData(fileBytes, SettableMetadata(contentType: 'image/jpeg'));
      return ref.fullPath;
    } catch (e) {
      debugPrint("Error uploading image: $e");
      rethrow;
    }
  }

  Future<Uint8List?> downloadProfileImage(String path) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Authentication is required.');
    if (path != 'profile_images/$uid.jpg') {
      throw ArgumentError.value(path, 'path', 'Invalid profile image path.');
    }
    return _storage.ref(path).getData(maxProfileImageBytes);
  }
}

void validateProfileImageBytes(Uint8List fileBytes) {
  final isJpeg =
      fileBytes.lengthInBytes >= 3 &&
      fileBytes[0] == 0xff &&
      fileBytes[1] == 0xd8 &&
      fileBytes[2] == 0xff;
  if (!isJpeg ||
      fileBytes.lengthInBytes > StorageService.maxProfileImageBytes) {
    throw ArgumentError.value(
      fileBytes.lengthInBytes,
      'fileBytes',
      'Profile images must be JPEG files no larger than 5 MiB.',
    );
  }
}
