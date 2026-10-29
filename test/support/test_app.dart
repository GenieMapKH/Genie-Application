import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/theme/app_theme.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/settings/data/app_settings_storage.dart';
import 'package:tilomnov/features/settings/providers/app_settings_providers.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps [home] inside the real app shell: both themes, both languages and
/// the saved settings (starting from [savedSettings]), so a test can switch
/// theme or language the way a user does.
Future<void> pumpTestApp(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const [],
  Map<String, Object> savedSettings = const {},
}) async {
  SharedPreferences.setMockInitialValues(savedSettings);
  final storage = AppSettingsStorage(await SharedPreferences.getInstance());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appSettingsStorageProvider.overrideWithValue(storage),
        ...overrides,
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ref.watch(themeModeProvider),
          locale: ref.watch(localeProvider),
          supportedLocales: AppLanguages.all,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: home,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Treats the test as signed in, or as a guest, without stored tokens.
Override signedInOverride({bool signedIn = true}) =>
    isSignedInProvider.overrideWith(() => _FixedSignedIn(signedIn));

class _FixedSignedIn extends SignedInNotifier {
  final bool signedIn;

  _FixedSignedIn(this.signedIn);

  @override
  bool build() => signedIn;
}

/// A request the [StubServer] received.
typedef ReceivedRequest = ({String method, String path, Object? body});

/// Stands in for the API: answers every request with what [respond] returns
/// (status code and JSON body) and remembers what it was asked.
class StubServer implements HttpClientAdapter {
  final (int, String) Function(RequestOptions request) respond;
  final List<ReceivedRequest> requests = [];

  StubServer(this.respond);

  /// A server that always answers [status] with [body].
  StubServer.always(int status, [String body = '{}'])
    : respond = ((_) => (status, body));

  Dio get dio =>
      Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = this;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add((
      method: options.method,
      path: options.path,
      body: options.data,
    ));
    final (status, body) = respond(options);
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
