import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/property/data/repositories/property_repository.dart';
import 'package:image_picker/image_picker.dart';

import '../../support/test_app.dart';

const _listing =
    '{"id": "p-1", "title": "Land", "price": "1", "propertyType": "Land", '
    '"status": "Draft", "createdAt": "2026-10-01T00:00:00.000Z", "images": []}';

/// Stands in for the storage host, remembering every upload.
class _Storage implements HttpClientAdapter {
  final List<({String url, String? type})> uploads = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    uploads.add((
      url: options.uri.toString(),
      type: options.headers[Headers.contentTypeHeader] as String?,
    ));
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('uploads each photo to its own link, as a picture, and confirms '
      'the names the server gave', () async {
    // The server renames files: spaces and other characters become "_".
    final api = StubServer(
      (request) => request.path.endsWith('presigned-url')
          ? (
              200,
              jsonEncode([
                {
                  'fileName': 'u/p-1/a-front_door.jpg',
                  'signedUrl': 'https://s/1',
                },
                {'fileName': 'u/p-1/b-garden.jpg', 'signedUrl': 'https://s/2'},
              ]),
            )
          : (200, _listing),
    );
    final storage = _Storage();
    final repo = PropertyRepository(
      api.dio,
      storageDio: Dio()..httpClientAdapter = storage,
    );

    await repo.uploadImages('p-1', [
      XFile.fromData(
        Uint8List(3),
        name: 'front door.jpg',
        mimeType: 'image/jpeg',
      ),
      XFile.fromData(Uint8List(3), name: 'garden.jpg', mimeType: 'image/jpeg'),
    ]);

    expect(storage.uploads.map((u) => u.url), ['https://s/1', 'https://s/2']);
    expect(storage.uploads.map((u) => u.type), everyElement('image/jpeg'));
    expect(api.requests.last.path, '/properties/p-1/images/confirm');
    expect(api.requests.last.body, {
      'fileNames': ['u/p-1/a-front_door.jpg', 'u/p-1/b-garden.jpg'],
    });
  });
}
