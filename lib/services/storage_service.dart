import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload Profile Image
  Future<String> uploadProfileImage(Uint8List fileBytes, String uid) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$uid.jpg');
      
      // Upload task
      final uploadTask = ref.putData(fileBytes, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask;
      
      // Get URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      rethrow;
    }
  }
}
