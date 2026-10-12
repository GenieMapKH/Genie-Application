import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/data/chat_repository.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/e2ee/crypto_service.dart';
import 'package:genie/features/chat/models/chat_attachment.dart';

/// Sends and opens files in a chat. A file is encrypted on this device with
/// a one-time key before it is uploaded, and decrypted only in memory.
class ChatAttachmentService {
  static const maxBytes = 20 * 1024 * 1024;

  /// How many opened files are kept in memory so scrolling does not
  /// download them again. Nothing decrypted is written to disk.
  static const _cacheSize = 30;

  final ChatRepository repository;
  final CryptoService cryptoService;

  final _opened = <String, Uint8List>{};

  ChatAttachmentService({
    required this.repository,
    required this.cryptoService,
  });

  /// Encrypts and uploads [bytes] for [recipientId]. The result goes inside
  /// the encrypted message; without it the stored file is unreadable.
  Future<ChatAttachment> send(
    Uint8List bytes, {
    required String recipientId,
    required String name,
    required String mimeType,
  }) async {
    if (bytes.length > maxBytes) {
      throw const ChatSendException('This file is too large (limit 20 MB).');
    }

    final sealed = cryptoService.encryptFile(bytes);
    final String path;
    try {
      path = await repository.uploadEncryptedFile(recipientId, sealed.cipher);
    } on DioException catch (e) {
      AppLogger.error('Attachment upload failed', e);
      throw const ChatSendException(
        'Could not upload the file. Check your connection.',
      );
    }

    _remember(path, bytes);
    return ChatAttachment(
      path: path,
      key: sealed.key,
      nonce: sealed.nonce,
      name: name,
      mimeType: mimeType,
      size: bytes.length,
    );
  }

  /// The decrypted file. Throws if it cannot be fetched, or if it is not
  /// exactly the file the sender encrypted.
  Future<Uint8List> open(ChatAttachment attachment) async {
    final cached = _opened[attachment.path];
    if (cached != null) return cached;

    final encrypted = await repository.downloadEncryptedFile(attachment.path);
    final bytes = cryptoService.decryptFile(
      encrypted,
      attachment.key,
      attachment.nonce,
    );
    _remember(attachment.path, bytes);
    return bytes;
  }

  void _remember(String path, Uint8List bytes) {
    _opened.remove(path);
    _opened[path] = bytes;
    while (_opened.length > _cacheSize) {
      _opened.remove(_opened.keys.first);
    }
  }
}
