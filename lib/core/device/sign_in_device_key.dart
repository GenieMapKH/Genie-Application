import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:tilomnov/core/logging/app_logger.dart';

/// Where [SignInDeviceKey] keeps its value. Reading and writing is all it needs.
abstract class DeviceKeyStore {
  Future<String?> read();
  Future<void> write(String value);
}

class SecureDeviceKeyStore implements DeviceKeyStore {
  static const _key = 'sign_in_device_key';
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
}

/// A secret this device makes up once and keeps, even across sign-outs.
///
/// The server remembers the devices that signed in to an account with it, so
/// someone guessing that account's password elsewhere cannot lock this device
/// out. It is only ever sent to the sign-in endpoints.
class SignInDeviceKey {
  final DeviceKeyStore _store;
  final Random _random;
  Future<String?>? _key;

  SignInDeviceKey({DeviceKeyStore? store, Random? random})
    : _store = store ?? SecureDeviceKeyStore(),
      _random = random ?? Random.secure();

  /// Null when the secure storage cannot be used: sign-in still works, just
  /// without this protection.
  Future<String?> read() => _key ??= _readOrCreate();

  Future<String?> _readOrCreate() async {
    try {
      final stored = await _store.read();
      if (stored != null && stored.length >= 43) return stored;

      final created = base64Url
          .encode(List<int>.generate(32, (_) => _random.nextInt(256)))
          .replaceAll('=', '');
      await _store.write(created);
      return created;
    } catch (e, stackTrace) {
      // Remembered as missing for this run, so the storage is not asked again.
      AppLogger.error('The sign-in device key is unavailable', e, stackTrace);
      return null;
    }
  }
}
