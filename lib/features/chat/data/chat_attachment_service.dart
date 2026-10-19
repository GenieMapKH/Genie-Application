import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/data/chat_attachment_store.dart';
import 'package:genie/features/chat/data/chat_repository.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/e2ee/keys/crypto_service.dart';
import 'package:genie/features/chat/models/chat_attachment.dart';
import 'package:genie/features/chat/models/chat_send_problem.dart';
import 'package:genie/features/chat/models/chat_voice.dart';

/// Sends and opens files in a chat. A file is encrypted on this device with
/// a one-time key before it is uploaded, and decrypted only in memory.
class ChatAttachmentService {
  /// The server's storage refuses anything above 12 MB; the encrypted file
  /// is only a few bytes larger than the original.
  static const maxBytes = 10 * 1024 * 1024;

  /// How many opened files, and how many bytes of them, are kept in memory
  /// so scrolling back shows them at once. Nothing decrypted is written to
  /// disk: [store] keeps only the encrypted files.
  static const _memoryFiles = 30;
  static const _memoryBytes = 64 * 1024 * 1024;

  final ChatRepository repository;
  final CryptoService cryptoService;
  final ChatAttachmentStore store;

  /// Opened files by path, least recently used first.
  final _opened = <String, Uint8List>{};
  int _openedBytes = 0;

  ChatAttachmentService({
    required this.repository,
    required this.cryptoService,
    required this.store,
  });

  /// Encrypts and uploads [bytes] for [recipientId]. The result goes inside
  /// the encrypted message; without it the stored file is unreadable. A
  /// voice message passes its [voice] details, which travel with the key.
  Future<ChatAttachment> send(
    Uint8List bytes, {
    required String recipientId,
    required String name,
    required String mimeType,
    ChatVoiceDetails? voice,
  }) async {
    if (bytes.length > maxBytes) {
      throw const ChatSendException(ChatSendProblem.fileTooLarge);
    }

    final sealed = cryptoService.encryptFile(bytes);
    final String path;
    try {
      path = await repository.uploadEncryptedFile(recipientId, sealed.cipher);
    } on DioException catch (e) {
      AppLogger.error('Attachment upload failed', e);
      throw const ChatSendException(ChatSendProblem.uploadFailed);
    }

    _remember(path, bytes);
    await store.write(path, sealed.cipher);
    return ChatAttachment(
      path: path,
      key: sealed.key,
      nonce: sealed.nonce,
      name: name,
      mimeType: mimeType,
      size: bytes.length,
      voice: voice,
    );
  }

  /// The decrypted file. Throws if it cannot be fetched, or if it is not
  /// exactly the file the sender encrypted.
  ///
  /// Looked for in memory, then in [store], and only then downloaded.
  Future<Uint8List> open(ChatAttachment attachment) async {
    final inMemory = cached(attachment);
    if (inMemory != null) return inMemory;

    final bytes = await _openStored(attachment) ?? await _download(attachment);
    _remember(attachment.path, bytes);
    return bytes;
  }

  /// The file if it was opened recently, without waiting: lets a picture be
  /// drawn in the same frame instead of after a loading placeholder.
  Uint8List? cached(ChatAttachment attachment) {
    final bytes = _opened.remove(attachment.path);
    if (bytes != null) _opened[attachment.path] = bytes;
    return bytes;
  }

  /// Null when nothing is stored, or the stored copy no longer opens (then
  /// it is dropped and downloaded again).
  Future<Uint8List?> _openStored(ChatAttachment attachment) async {
    final encrypted = await store.read(attachment.path);
    if (encrypted == null) return null;
    try {
      return cryptoService.decryptFile(
        encrypted,
        attachment.key,
        attachment.nonce,
      );
    } catch (e) {
      AppLogger.error('Stored chat file did not open; downloading it', e);
      await store.remove(attachment.path);
      return null;
    }
  }

  Future<Uint8List> _download(ChatAttachment attachment) async {
    final encrypted = await repository.downloadEncryptedFile(attachment.path);
    // Opened before storing: a file that fails to open is not kept.
    final bytes = cryptoService.decryptFile(
      encrypted,
      attachment.key,
      attachment.nonce,
    );
    await store.write(attachment.path, encrypted);
    return bytes;
  }

  void _remember(String path, Uint8List bytes) {
    final replaced = _opened.remove(path);
    if (replaced != null) _openedBytes -= replaced.length;
    _opened[path] = bytes;
    _openedBytes += bytes.length;

    while (_opened.length > 1 &&
        (_opened.length > _memoryFiles || _openedBytes > _memoryBytes)) {
      final oldest = _opened.keys.first;
      _openedBytes -= _opened.remove(oldest)!.length;
    }
  }
}
