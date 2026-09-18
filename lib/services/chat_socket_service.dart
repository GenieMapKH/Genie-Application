import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:genie/services/crypto_service.dart';
import 'package:genie/services/key_service.dart';
import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String recipientId;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.text,
    required this.createdAt,
  });
}

class ChatSocketService {
  final CryptoService cryptoService;
  final KeyService keyService;
  final Dio dio;
  IO.Socket? _socket;
  
  // Stream controller to broadcast new messages to the UI
  final _messagesController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get onMessageReceived => _messagesController.stream;

  ChatSocketService({
    required this.cryptoService,
    required this.keyService,
    required this.dio,
  });

  Future<void> connect() async {
    final token = await AuthStorage.getAccessToken();
    if (token == null) return;

    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://gateway-production-c0c5.up.railway.app';

    _socket = IO.io(
      '$baseUrl/chat', // Adjust this to match your gateway URL
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'authorization': 'Bearer $token'})
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket?.onConnect((_) {
      print('Socket.io connected');
      // On reconnect, we should sync offline messages
      _syncOfflineMessages();
    });

    _socket?.on('newMessage', (data) async {
      final decrypted = await decryptMessagePayload(data);
      if (decrypted != null) {
        _messagesController.add(decrypted);
      }
    });

    _socket?.onDisconnect((_) {
      print('Socket.io disconnected');
    });

    _socket?.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  Future<void> sendMessage(String recipientId, String text) async {
    try {
      // 1. Fetch recipient's public key from the backend
      final response = await dio.get('/chat/keys/$recipientId');
      final recipientPubKeyBase64 = response.data['identityPublicKey'];
      if (recipientPubKeyBase64 == null) {
        throw Exception('Recipient has no public key');
      }

      final recipientPubKey = base64Decode(recipientPubKeyBase64);

      // 2. Get our local keypair
      final keyPair = await keyService.getIdentityKeyPair();
      if (keyPair == null) {
        throw Exception('E2EE not initialized');
      }

      // 3. Encrypt the message
      final encrypted = cryptoService.encryptMessage(
        text,
        recipientPubKey,
        keyPair.secretKey,
      );

      // 4. Emit the encrypted payload
      _socket?.emit('sendMessage', {
        'recipientId': recipientId,
        'ciphertext': encrypted['ciphertext'],
        'nonce': encrypted['nonce'],
      });
      
    } catch (e) {
      print('Failed to send message: $e');
    }
  }

  Future<void> _syncOfflineMessages() async {
    try {
      // Typically you'd store the lastMessageTime in a local SQLite DB, 
      // but for now we fetch all or from a specific date.
      // Let's assume we are fetching from a recent timestamp or local storage.
      final response = await dio.get('/chat/sync');
      final List messages = response.data;

      for (var msg in messages) {
        final decrypted = await decryptMessagePayload(msg);
        if (decrypted != null) {
          _messagesController.add(decrypted);
        }
      }
    } catch (e) {
      print('Offline sync failed: $e');
    }
  }

  Future<ChatMessage?> decryptMessagePayload(Map<String, dynamic> data, {String? currentUserId}) async {
    try {
      final senderId = data['senderId'];
      final recipientId = data['recipientId'];

      final keyPair = await keyService.getIdentityKeyPair();
      if (keyPair == null) return null;

      // Determine which participant's public key we need:
      String otherUserId;
      if (currentUserId != null && senderId == currentUserId) {
        otherUserId = recipientId;
      } else {
        otherUserId = senderId;
      }

      var response = await dio.get('/chat/keys/$otherUserId');
      var otherPubKeyBase64 = response.data['identityPublicKey'];

      if (otherPubKeyBase64 == null && otherUserId != recipientId) {
        otherUserId = recipientId;
        response = await dio.get('/chat/keys/$otherUserId');
        otherPubKeyBase64 = response.data['identityPublicKey'];
      }

      if (otherPubKeyBase64 == null) return null;

      final otherPubKey = base64Decode(otherPubKeyBase64);

      final plaintext = cryptoService.decryptMessage(
        data['ciphertext'],
        data['nonce'],
        otherPubKey,
        keyPair.secretKey,
      );

      return ChatMessage(
        id: data['id'],
        senderId: senderId,
        recipientId: recipientId,
        text: plaintext,
        createdAt: DateTime.parse(data['createdAt']),
      );
    } catch (e) {
      try {
        final recipientId = data['recipientId'];
        final senderId = data['senderId'];
        final keyPair = await keyService.getIdentityKeyPair();
        if (keyPair == null) return null;

        final response = await dio.get('/chat/keys/$recipientId');
        final pubKeyBase64 = response.data['identityPublicKey'];
        if (pubKeyBase64 == null) return null;

        final plaintext = cryptoService.decryptMessage(
          data['ciphertext'],
          data['nonce'],
          base64Decode(pubKeyBase64),
          keyPair.secretKey,
        );

        return ChatMessage(
          id: data['id'],
          senderId: senderId,
          recipientId: recipientId,
          text: plaintext,
          createdAt: DateTime.parse(data['createdAt']),
        );
      } catch (_) {
        print('Failed to decrypt message payload: $e');
        return null;
      }
    }
  }
}
