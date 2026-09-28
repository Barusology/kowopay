import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kowopay/services/storage_service.dart';

void main() {
  test('accepts JPEG image bytes within the upload size limit', () {
    expect(
      () => validateProfileImageBytes(Uint8List.fromList([0xff, 0xd8, 0xff])),
      returnsNormally,
    );
  });

  test('rejects empty and non-JPEG image bytes', () {
    expect(() => validateProfileImageBytes(Uint8List(0)), throwsArgumentError);
    expect(
      () => validateProfileImageBytes(
        Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]),
      ),
      throwsArgumentError,
    );
  });

  test('rejects profile images larger than five MiB', () {
    final oversized = Uint8List(StorageService.maxProfileImageBytes + 1)
      ..[0] = 0xff
      ..[1] = 0xd8
      ..[2] = 0xff;

    expect(() => validateProfileImageBytes(oversized), throwsArgumentError);
  });
}
