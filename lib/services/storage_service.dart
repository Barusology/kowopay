import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:kowopay/utils/rate_limiter.dart';
import 'package:kowopay/utils/secure_logger.dart';
import 'package:kowopay/utils/validators.dart';

class StorageException implements Exception {
  StorageException(this.message);
  final String message;
  @override
  String toString() => message;
}

class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads a validated avatar. Returns a Firebase Storage download URL.
  ///
  /// The file type is sniffed from magic bytes rather than trusting the
  /// filename/MIME hint, and the same size/content-type limits are re-enforced
  /// by `storage.rules`.
  Future<String> uploadProfileImage(Uint8List fileBytes, String uid) async {
    if (!Validators.isSafeUid(uid)) {
      throw StorageException('Invalid account identifier.');
    }
    final String? validationError = ImageFileValidator.validate(fileBytes);
    if (validationError != null) {
      throw StorageException(validationError);
    }

    final String contentType = ImageFileValidator.contentTypeOf(fileBytes);
    final Reference ref = _storage
        .ref()
        .child('profile_images')
        .child(uid)
        .child('avatar');

    try {
      final SettableMetadata metadata = SettableMetadata(
        contentType: contentType,
        cacheControl: 'public, max-age=3600',
      );
      final UploadTask task = ref.putData(fileBytes, metadata);
      final TaskSnapshot snapshot = await task;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      if (!Validators.isSafeImageUrl(downloadUrl)) {
        // Never persist a URL that does not belong to our storage bucket.
        await snapshot.ref.delete();
        throw StorageException('Unexpected upload location.');
      }
      return downloadUrl;
    } on StorageException {
      rethrow;
    } on FirebaseException catch (e) {
      SecureLog.error('Storage upload', e);
      throw StorageException('Image upload failed. Please try again.');
    }
  }
}
