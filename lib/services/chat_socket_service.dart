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
      final decrypted = await _decryptMessagePayload(data);
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
        final decrypted = await _decryptMessagePayload(msg);
        if (decrypted != null) {
          _messagesController.add(decrypted);
        }
      }
    } catch (e) {
      print('Offline sync failed: $e');
    }
  }

  Future<ChatMessage?> _decryptMessagePayload(Map<String, dynamic> data) async {
    try {
      final senderId = data['senderId'];
      
      // 1. Fetch sender's public key
      final response = await dio.get('/chat/keys/$senderId');
      final senderPubKeyBase64 = response.data['identityPublicKey'];
      final senderPubKey = base64Decode(senderPubKeyBase64);

      // 2. Get our private key
      final keyPair = await keyService.getIdentityKeyPair();
      if (keyPair == null) return null;

      // 3. Decrypt
      final plaintext = cryptoService.decryptMessage(
        data['ciphertext'],
        data['nonce'],
        senderPubKey,
        keyPair.secretKey,
      );

      return ChatMessage(
        id: data['id'],
        senderId: senderId,
        recipientId: data['recipientId'],
        text: plaintext,
        createdAt: DateTime.parse(data['createdAt']),
      );
    } catch (e) {
      print('Failed to decrypt incoming message: $e');
      return null;
    }
  }
}
