import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilomnov/core/storage/kept_copy_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  KeptCopyStore storeOf(String? account) =>
      KeptCopyStore(account: () async => account);

  Future<String?> titleIn(KeptCopyStore store) =>
      store.read('page', parse: (json) => json['title'] as String);

  test('gives back what was kept, for the same account only', () async {
    await storeOf('sokha').write('page', {'title': 'Mine'});

    expect(await titleIn(storeOf('sokha')), 'Mine');
    expect(await titleIn(storeOf('dara')), isNull);
  });

  test('keeps nothing without an account', () async {
    await storeOf(null).write('page', {'title': 'Nobody'});

    expect(await titleIn(storeOf(null)), isNull);
  });

  test('a copy that can no longer be read is none, not an error', () async {
    await storeOf('sokha').write('page', {'title': 42});

    expect(await titleIn(storeOf('sokha')), isNull);
  });

  test('an account that cannot be found keeps and reads nothing', () async {
    final broken = KeptCopyStore(account: () => throw StateError('locked'));

    await broken.write('page', {'title': 'Lost'});
    expect(await titleIn(broken), isNull);
  });
}
