import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/device/sign_in_device_key.dart';

class _MemoryStore implements DeviceKeyStore {
  String? value;
  int writes = 0;
  bool broken = false;

  @override
  Future<String?> read() async {
    if (broken) throw Exception('storage unavailable');
    return value;
  }

  @override
  Future<void> write(String newValue) async {
    writes++;
    value = newValue;
  }
}

void main() {
  test('makes a key the server accepts, once, and keeps it', () async {
    final store = _MemoryStore();

    final first = await SignInDeviceKey(store: store).read();
    final again = await SignInDeviceKey(store: store).read();

    expect(first, matches(RegExp(r'^[A-Za-z0-9_-]{43,128}$')));
    expect(again, first);
    expect(store.writes, 1);
  });

  test('two devices get different keys', () async {
    final a = await SignInDeviceKey(store: _MemoryStore()).read();
    final b = await SignInDeviceKey(store: _MemoryStore()).read();

    expect(a, isNot(b));
  });

  test('sends none when the storage cannot be used', () async {
    final store = _MemoryStore()..broken = true;

    expect(await SignInDeviceKey(store: store).read(), isNull);
  });
}
