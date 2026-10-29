import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/media/image_compressor.dart';
import 'package:tilomnov/core/media/image_upload_policy.dart';
import 'package:image_picker/image_picker.dart';

const _policy = ImageUploadPolicy(
  shortSide: 1000,
  targetBytes: 100,
  maxBytes: 500,
);

/// A picture file that only claims to be [originalBytes] bytes: nothing is
/// read or allocated.
XFile _picture({String name = 'IMG_0001.heic', int originalBytes = 1000}) {
  return _FakeFile('/photos/$name', originalBytes);
}

/// An encoder that records every attempt and answers with [sizeOf].
class _Encoder {
  final int Function(int shortSide, int quality) sizeOf;
  final List<({int shortSide, int quality})> attempts = [];

  _Encoder(this.sizeOf);

  Future<Uint8List?> call(
    String path, {
    required int shortSide,
    required int quality,
  }) async {
    attempts.add((shortSide: shortSide, quality: quality));
    final size = sizeOf(shortSide, quality);
    return size < 0 ? null : Uint8List(size);
  }
}

void main() {
  group('ImageCompressor', () {
    test('stops at the first quality that is small enough', () async {
      final encoder = _Encoder((_, quality) => quality == 75 ? 80 : 400);

      final image = await ImageCompressor(
        encoder.call,
      ).compress(_picture(), _policy);

      expect(image.bytes, hasLength(80));
      expect(encoder.attempts.map((a) => a.quality), [85, 75]);
      expect(encoder.attempts.map((a) => a.shortSide).toSet(), {1000});
    });

    test('always hands over a JPEG, named after the original', () async {
      final encoder = _Encoder((_, _) => 50);
      final compressor = ImageCompressor(encoder.call);

      final heic = await compressor.compress(_picture(), _policy);
      final screenshot = await compressor.compress(
        _picture(name: 'Screenshot 2026.png'),
        _policy,
      );
      final unnamed = await compressor.compress(_picture(name: ''), _policy);

      expect([heic.name, heic.mimeType], ['IMG_0001.jpg', 'image/jpeg']);
      expect(screenshot.name, 'Screenshot 2026.jpg');
      expect(unnamed.name, 'image.jpg');
    });

    test(
      'makes the picture smaller too when quality alone is not enough',
      () async {
        // Only a smaller picture gets under the target.
        final encoder = _Encoder((shortSide, _) => shortSide < 1000 ? 90 : 300);

        final image = await ImageCompressor(
          encoder.call,
        ).compress(_picture(), _policy);

        expect(image.bytes, hasLength(90));
        expect(encoder.attempts, hasLength(6));
        // 1000 px at five qualities, then 700 px.
        expect(encoder.attempts.last, (shortSide: 700, quality: 85));
      },
    );

    test('accepts a picture above the target but within the limit', () async {
      final encoder = _Encoder((_, _) => 300);

      final image = await ImageCompressor(
        encoder.call,
      ).compress(_picture(), _policy);

      expect(image.bytes, hasLength(300));
      // Both passes were tried before settling.
      expect(encoder.attempts, hasLength(10));
    });

    test('refuses a picture that stays above the limit', () async {
      final encoder = _Encoder((_, _) => 600);

      await expectLater(
        ImageCompressor(encoder.call).compress(_picture(), _policy),
        throwsA(
          isA<ImageRejectedException>().having(
            (e) => e.reason,
            'reason',
            ImageRejection.stillTooLarge,
          ),
        ),
      );
    });

    test('refuses a file the device cannot decode', () async {
      final encoder = _Encoder((_, _) => -1);

      await expectLater(
        ImageCompressor(encoder.call).compress(_picture(), _policy),
        throwsA(
          isA<ImageRejectedException>().having(
            (e) => e.reason,
            'reason',
            ImageRejection.unreadable,
          ),
        ),
      );
    });

    test('refuses a file over the source limit without reading it', () async {
      final encoder = _Encoder((_, _) => 50);
      final huge = _picture(
        originalBytes: ImageUploadPolicy.maxSourceBytes + 1,
      );

      await expectLater(
        ImageCompressor(encoder.call).compress(huge, _policy),
        throwsA(
          isA<ImageRejectedException>().having(
            (e) => e.reason,
            'reason',
            ImageRejection.sourceTooLarge,
          ),
        ),
      );
      expect(encoder.attempts, isEmpty);
    });

    test('accepts a file exactly at the source limit', () async {
      final encoder = _Encoder((_, _) => 50);
      final atLimit = _picture(originalBytes: ImageUploadPolicy.maxSourceBytes);

      final image = await ImageCompressor(
        encoder.call,
      ).compress(atLimit, _policy);

      expect(image.bytes, hasLength(50));
    });
  });

  group('policies', () {
    test(
      'every limit is a real reduction, and the strictest is the profile picture',
      () {
        const policies = [
          ImageUploadPolicy.avatar,
          ImageUploadPolicy.chatPhoto,
          ImageUploadPolicy.propertyPhoto,
        ];

        for (final policy in policies) {
          expect(policy.targetBytes, lessThan(policy.maxBytes));
          expect(policy.maxBytes, lessThan(ImageUploadPolicy.maxSourceBytes));
        }
        expect(
          ImageUploadPolicy.avatar.maxBytes,
          lessThan(ImageUploadPolicy.chatPhoto.maxBytes),
        );
      },
    );

    test('the source limit is 500 MB', () {
      expect(ImageUploadPolicy.maxSourceBytes, 500 * 1024 * 1024);
    });
  });
}

class _FakeFile extends XFile {
  final int size;

  _FakeFile(super.path, this.size);

  @override
  Future<int> length() async => size;
}
