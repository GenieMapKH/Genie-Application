import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:tilomnov/features/profile/data/models/user_profile.dart';

/// API access for the profile picture. Each call returns the profile as it
/// is afterwards.
class AvatarRepository {
  final Dio dio;

  /// For the signed upload link. It carries its own permission, so this
  /// client sends no session token to the storage host.
  final Dio storageDio;

  AvatarRepository(this.dio, {Dio? storageDio})
    : storageDio = storageDio ?? Dio();

  /// Stores [bytes] as the new picture: the server says where to put the
  /// file, the file goes straight to storage, then the server is told to
  /// use it.
  Future<UserProfile> upload(
    Uint8List bytes, {
    required String mimeType,
  }) async {
    final location = await dio.post('/users/me/avatar/upload');
    final upload = location.data as Map<String, dynamic>;

    await storageDio.put<void>(
      upload['uploadUrl'] as String,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          Headers.contentLengthHeader: bytes.length,
          Headers.contentTypeHeader: mimeType,
        },
      ),
    );

    final response = await dio.put(
      '/users/me/avatar',
      data: {'path': upload['path']},
    );
    return _profile(response);
  }

  /// "Sync from Google account": the picture becomes [photoUrl], the Google
  /// account's photo, and the server keeps it up to date from then on.
  Future<UserProfile> useGooglePhoto(String photoUrl) async {
    final response = await dio.put(
      '/users/me/avatar/google',
      data: {'photoUrl': photoUrl},
    );
    return _profile(response);
  }

  Future<UserProfile> remove() async {
    return _profile(await dio.delete('/users/me/avatar'));
  }

  UserProfile _profile(Response<dynamic> response) =>
      UserProfile.fromJson(response.data as Map<String, dynamic>);
}
