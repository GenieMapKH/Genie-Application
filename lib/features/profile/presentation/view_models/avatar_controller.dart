import 'dart:typed_data';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/profile/data/repositories/avatar_repository.dart';

/// How a change of profile picture ended. The screen turns this into a message.
enum AvatarResult {
  changed,

  /// The Google account picker was closed.
  cancelled,

  /// "Sync from Google" was asked for, but that account has no photo.
  noGooglePhoto,
  failed,
}

/// Changes the profile picture. No UI: the picture arrives as bytes, and
/// the Google photo's address comes from [_readGooglePhoto].
class AvatarController {
  final AvatarRepository _repository;

  /// The Google account's photo (`url` is null when it has none), or null
  /// when the user backed out of signing in to Google.
  final Future<({String? url})?> Function() _readGooglePhoto;

  /// Called after every change, so the profile is loaded again.
  final void Function() _onChanged;

  AvatarController(
    this._repository, {
    required Future<({String? url})?> Function() readGooglePhoto,
    required void Function() onChanged,
  }) : _readGooglePhoto = readGooglePhoto,
       _onChanged = onChanged;

  /// A picture taken with the camera or chosen from the phone.
  Future<AvatarResult> upload(Uint8List bytes, {required String mimeType}) {
    return _change(
      'upload the profile picture',
      () => _repository.upload(bytes, mimeType: mimeType),
    );
  }

  /// The "Sync from Google account" tick box. On: the picture is the Google
  /// photo and follows it. Off: the account goes back to having no picture.
  Future<AvatarResult> setGoogleSync(bool enabled) async {
    if (!enabled) return remove();

    final ({String? url})? photo;
    try {
      photo = await _readGooglePhoto();
    } catch (e) {
      AppLogger.error('Could not read the Google photo', e);
      return AvatarResult.failed;
    }
    if (photo == null) return AvatarResult.cancelled;
    final url = photo.url;
    if (url == null) return AvatarResult.noGooglePhoto;

    return _change(
      'sync the profile picture from Google',
      () => _repository.useGooglePhoto(url),
    );
  }

  Future<AvatarResult> remove() =>
      _change('remove the profile picture', _repository.remove);

  Future<AvatarResult> _change(
    String what,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      AppLogger.error('Could not $what', e);
      return AvatarResult.failed;
    }
    _onChanged();
    return AvatarResult.changed;
  }
}
