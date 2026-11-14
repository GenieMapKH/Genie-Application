// Security regressions: the formerly vulnerable outcomes must remain impossible.
// All accounts, tokens, messages and API responses below are fabricated.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilomnov/core/network/api_cache_manager.dart';
import 'package:tilomnov/features/chat/data/chat_repository.dart';
import 'package:tilomnov/features/chat/data/message_codec.dart';
import 'package:tilomnov/features/chat/models/chat_attachment.dart';
import 'package:tilomnov/features/profile/data/repositories/user_repository.dart';

class _FixtureApi extends Interceptor {
  final entered = Completer<void>();
  final answer = Completer<Map<String, dynamic>>();
  bool offline = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (offline) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
        true,
      );
      return;
    }
    if (!entered.isCompleted) entered.complete();
    final body = await answer.future;
    handler.resolve(
      Response(requestOptions: options, statusCode: 200, data: body),
      true,
    );
  }
}

Map<String, dynamic> _profile(String account) => {
  'id': account,
  'email': '$account@example.invalid',
  'createdAt': '2026-11-12T00:00:00Z',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    ApiCacheManager().clearAll();
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'F03: late responses are cancelled and never repopulate the next session cache',
    () async {
      final api = _FixtureApi();
      final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'))
        ..interceptors.addAll([CacheInterceptor(), api]);
      final alice = dio.get(
        '/users/me',
        options: Options(headers: {'Authorization': 'Bearer fixture-alice'}),
      );
      await api.entered.future;
      ApiCacheManager().clearAll(); // Actual logout cache action.
      api.answer.complete(_profile('alice'));
      await expectLater(alice, throwsA(isA<DioException>()));
      api.offline = true;
      await expectLater(
        dio.get(
          '/users/me',
          options: Options(headers: {'Authorization': 'Bearer fixture-bob'}),
        ),
        throwsA(isA<DioException>()),
      );
      ApiCacheManager().clearAll();
      await expectLater(dio.get('/users/me'), throwsA(isA<DioException>()));
      dio.close(force: true);
    },
  );

  test(
    'F03: a delayed profile cannot be saved or returned for the next account',
    () async {
      var account = 'alice';
      final api = _FixtureApi();
      final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'))
        ..interceptors.add(api);
      final repository = UserRepository(dio, accountId: () async => account);
      final alice = repository.getProfile();
      await api.entered.future;
      account = 'bob';
      api.answer.complete(_profile('alice'));
      await expectLater(alice, throwsStateError);
      expect(await repository.keptProfile(), isNull);
      final aliceCopy = UserRepository(dio, accountId: () async => 'alice');
      expect(await aliceCopy.keptProfile(), isNull);
      dio.close(force: true);
    },
  );

  test(
    'F03 negative control: stable account keeps its profile isolated',
    () async {
      final api = _FixtureApi();
      final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'))
        ..interceptors.add(api);
      final alice = UserRepository(dio, accountId: () async => 'alice');
      api.answer.complete(_profile('alice'));
      await alice.getProfile();
      final bob = UserRepository(dio, accountId: () async => 'bob');
      expect(await bob.keptProfile(), isNull);
      dio.close(force: true);
    },
  );

  test(
    'F04: preferences never persist message envelopes or attachment keys',
    () async {
      final api = _FixtureApi();
      final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'))
        ..interceptors.add(api);
      const alice = '11111111-1111-4111-8111-111111111111';
      const bob = '22222222-2222-4222-8222-222222222222';
      const fileId = '33333333-3333-4333-8333-333333333333';
      final body = await const MessageCodec(userId: alice).encode(
        'private fixture message',
        id: 'audit-message',
        peerId: bob,
        attachment: const ChatAttachment(
          path: '$alice/$bob/$fileId',
          key: 'fixture-file-key',
          nonce: 'fixture-file-nonce',
          name: 'fixture.jpg',
          mimeType: 'image/jpeg',
          size: 12,
        ),
      );
      api.answer.complete({
        'items': [
          {
            'participantId': bob,
            'lastMessage': {
              'id': 'audit-message',
              'senderId': alice,
              'createdAt': '2026-11-12T00:00:00Z',
              'ciphertext': body.ciphertext,
              'nonce': body.nonce,
            },
          },
        ],
        'nextCursor': null,
      });
      await ChatRepository(
        dio: dio,
        accountId: () async => alice,
      ).fetchConversationPage();
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(
        'chat.conversations.first_page.v1.$alice',
      );
      expect(raw, isNull);
      expect(preferences.getKeys(), isEmpty);
      // Logical account isolation works in the ordinary, non-racing case.
      final other = ChatRepository(dio: dio, accountId: () async => bob);
      expect(await other.keptFirstPage(), isNull);
      dio.close(force: true);
    },
  );
}
