import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:tilomnov/core/logging/app_logger.dart';

/// Chat files kept on this device, so a picture seen before opens without
/// downloading it again, even after the app restarts.
///
/// Only the encrypted bytes are written, never the opened file: without the
/// key, which travels inside the end-to-end encrypted message, a stored file
/// cannot be read. A file is stored under its server path, which never
/// changes. The store is a cache: when it fails, the file is downloaded.
class ChatAttachmentStore {
  /// Files not opened for this long are removed from the device.
  static const _keepUnused = Duration(days: 30);
  static const _maxFiles = 300;

  final CacheManager _files;

  ChatAttachmentStore({CacheManager? files})
    : _files =
          files ??
          CacheManager(
            Config(
              'tilomnov_chat_attachments',
              stalePeriod: _keepUnused,
              maxNrOfCacheObjects: _maxFiles,
            ),
          );

  /// The encrypted file stored for [path], or null when there is none.
  Future<Uint8List?> read(String path) async {
    try {
      final cached = await _files.getFileFromCache(path);
      return await cached?.file.readAsBytes();
    } catch (e, stackTrace) {
      AppLogger.error('Stored chat file could not be read', e, stackTrace);
      return null;
    }
  }

  Future<void> write(String path, Uint8List encrypted) async {
    try {
      await _files.putFile(
        path,
        encrypted,
        key: path,
        maxAge: _keepUnused,
        fileExtension: 'bin',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Chat file could not be stored', e, stackTrace);
    }
  }

  /// Forgets a stored file, e.g. one that no longer opens.
  Future<void> remove(String path) async {
    try {
      await _files.removeFile(path);
    } catch (e, stackTrace) {
      AppLogger.error('Stored chat file could not be removed', e, stackTrace);
    }
  }

  /// Removes every stored file, e.g. when another user signs in.
  Future<void> clear() async {
    try {
      await _files.emptyCache();
    } catch (e, stackTrace) {
      AppLogger.error('Stored chat files could not be removed', e, stackTrace);
    }
  }
}
