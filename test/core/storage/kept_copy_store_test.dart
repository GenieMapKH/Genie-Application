import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilomnov/core/storage/kept_copy_store.dart';
import 'package:tilomnov/core/network/api_cache_manager.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiCacheManager().clearAll();
  });

  KeptCopyStore storeOf(String? account) =>
      KeptCopyStore(account: () async => account);

  Future<String?> titleIn(KeptCopyStore store) =>
      store.read('page', parse: (json) => json['title'] as String);

  test('gives back what was kept, for the same account only', () async {
    await storeOf(
      'sokha',
    ).write('page', {'title': 'Mine'}, scope: await storeOf('sokha').capture());

    expect(await titleIn(storeOf('sokha')), 'Mine');
    expect(await titleIn(storeOf('dara')), isNull);
  });

  test('upgrade purges API copies but preserves unrelated settings', () async {
    SharedPreferences.setMockInitialValues({
      'profile.v1.sokha': 'private',
      'chat.conversations.first_page.v1.sokha': 'keys',
      'own_listings.first_page.v1.sokha': 'draft',
      'saved.first_page.v1.sokha': 'saved',
      'feed.first_page.v1.sokha': 'feed',
      'closest.first_page.v1.sokha': 'closest',
      'theme': 'dark',
    });
    await KeptCopyStore.purgeLegacyCopies();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getKeys(), {'theme'});
    expect(preferences.getString('theme'), 'dark');
  });

  test('same-account sign-in is still a different session', () async {
    final store = storeOf('sokha');
    final scope = await store.capture();
    ApiCacheManager().clearAll();
    await expectLater(
      store.write('page', {'title': 'Old'}, scope: scope),
      throwsStateError,
    );
    expect(await titleIn(store), isNull);
  });

  test(
    'session changes during the async owner check reject the old write',
    () async {
      final owner = Completer<String?>();
      final store = KeptCopyStore(account: () => owner.future);
      final scope = (owner: 'sokha', generation: ApiCacheManager().generation);
      final write = store.write('page', {'title': 'Old'}, scope: scope);
      ApiCacheManager().clearAll();
      owner.complete('sokha');
      await expectLater(write, throwsStateError);
      expect(await titleIn(storeOf('sokha')), isNull);
    },
  );

  test('keeps nothing without an account', () async {
    await storeOf(
      null,
    ).write('page', {'title': 'Nobody'}, scope: await storeOf(null).capture());

    expect(await titleIn(storeOf(null)), isNull);
  });

  test('a copy that can no longer be read is none, not an error', () async {
    await storeOf(
      'sokha',
    ).write('page', {'title': 42}, scope: await storeOf('sokha').capture());

    expect(await titleIn(storeOf('sokha')), isNull);
  });

  test('an account that cannot be found keeps and reads nothing', () async {
    final broken = KeptCopyStore(account: () => throw StateError('locked'));

    await broken.write('page', {
      'title': 'Lost',
    }, scope: await broken.capture());
    expect(await titleIn(broken), isNull);
  });
}
