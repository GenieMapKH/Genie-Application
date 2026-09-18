import 'package:flutter/material.dart';
import 'package:genie/services/key_service.dart';
import 'package:genie/services/backup_service.dart';
import 'package:genie/services/chat_socket_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:sodium_libs/sodium_libs.dart';

class E2EEInitService {
  final KeyService keyService;
  final BackupService backupService;
  final Dio dio;
  final ChatSocketService chatSocketService;

  E2EEInitService({
    required this.keyService,
    required this.backupService,
    required this.dio,
    required this.chatSocketService,
  });

  /// Call this after login / custom JWT issuance.
  Future<void> initializeE2EE(BuildContext context, String userId) async {
    final hasLocal = await keyService.hasLocalKeyPair();
    
    if (hasLocal) {
      // 1. Private key exists locally -> upload pubkey if needed -> connect socket -> done
      await keyService.uploadPublicKeyIfNeeded(userId);
      _connectSocket();
      return;
    }

    // 2. No private key locally. Check if backup exists.
    try {
      final response = await dio.get('/chat/backup');
      // 200: Backup exists
      final data = response.data;
      final blob = data['backupBlob'];
      final salt = data['backupSalt'];
      final nonce = data['backupNonce'];

      // Prompt for PIN to restore
      final pin = await _promptForPin(context, isNew: false);
      if (pin == null) return; // User cancelled

      try {
        final privateKeyBytes = await backupService.restoreBackup(pin, salt, nonce, blob);
        // We have the private key, now we need the public key to save the pair.
        // SecretBox decrypt doesn't give us the public key, but we can generate it from the secret key?
        // Wait, sodium_libs X25519 doesn't easily derive public from private without using `crypto.scalarmult.base(privateKey)`.
        // The easiest way is to let the user provide the public key from the backend?
        // Or generate it: `sodium.crypto.scalarmult.base(secretKey)`
        final sodium = keyService.cryptoService.sodium;
        final secretKey = sodium.secureCopy(Uint8List.fromList(privateKeyBytes));
        
        // Fetch public key from backend since sodium_libs doesn't expose scalarmult
        final keysResponse = await dio.get('/chat/keys/$userId');
        final publicKeyB64 = keysResponse.data['identityPublicKey'];
        final publicKey = base64Decode(publicKeyB64);
        
        await keyService.saveIdentityKeyPair(
          KeyPair(publicKey: publicKey, secretKey: secretKey)
        );
        
        await keyService.uploadPublicKeyIfNeeded(userId);
        _connectSocket();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to restore backup. Incorrect PIN?')),
          );
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // 404: Brand new identity
        final keyPair = await keyService.generateAndSaveIdentityKeyPair();
        
        // Prompt for new PIN to backup
        final pin = await _promptForPin(context, isNew: true);
        if (pin != null) {
          final backup = await backupService.createBackup(pin, keyPair.secretKey.extractBytes());
          await dio.post('/chat/backup', data: {
            'backupBlob': backup['blob'],
            'backupSalt': backup['salt'],
            'backupNonce': backup['nonce'],
          });
        }
        
        await keyService.uploadPublicKeyIfNeeded(userId);
        _connectSocket();
      } else if (e.response?.statusCode == 429) {
        // 429: Rate limited
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Too many attempts. Try again in 15 minutes.')),
          );
        }
      } else {
        // Other error
        print('E2EE Init Error: $e');
      }
    }
  }

  void _connectSocket() {
    print('E2EE Init Complete. Connecting to Chat Socket...');
    chatSocketService.connect();
  }

  Future<String?> _promptForPin(BuildContext context, {required bool isNew}) {
    String pin = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(isNew ? 'Create Backup PIN' : 'Enter Backup PIN'),
          content: TextField(
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            onChanged: (val) => pin = val,
            decoration: InputDecoration(
              hintText: '6-digit PIN',
              helperText: isNew 
                  ? 'This PIN encrypts your chat keys. Do not forget it!' 
                  : 'Enter your PIN to restore your chats.',
            ),
          ),
          actions: [
            if (!isNew)
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context, pin),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
