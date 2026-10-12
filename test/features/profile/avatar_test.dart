import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/data/repositories/avatar_repository.dart';
import 'package:genie/features/profile/presentation/view_models/avatar_controller.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/profile/presentation/widgets/avatar_options_sheet.dart';
import 'package:genie/shared/utils/image_mime_type.dart';

import '../../support/test_app.dart';

const _googlePhoto = 'https://lh3.googleusercontent.com/a/me';
const _profileJson =
    '{"id":"u1","role":"user","createdAt":"2026-01-01T00:00:00.000Z"}';

UserProfile _profile({
  String? firebaseUid,
  String? avatarUrl,
  bool avatarFromGoogle = false,
}) {
  return UserProfile(
    id: 'u1',
    role: 'user',
    createdAt: DateTime(2026),
    firebaseUid: firebaseUid,
    avatarUrl: avatarUrl,
    avatarFromGoogle: avatarFromGoogle,
  );
}

/// The API and the storage host in one: what the upload flow talks to.
StubServer _server() {
  return StubServer(
    (request) => request.path == '/users/me/avatar/upload'
        ? (
            201,
            '{"path":"u1/new-picture","uploadUrl":"https://storage.test/put-here"}',
          )
        : (200, _profileJson),
  );
}

/// Records what the sheet asked for, and answers as the test says.
class _FakeAvatarController extends Fake implements AvatarController {
  AvatarResult answer = AvatarResult.changed;
  final List<bool> syncRequests = [];
  int removals = 0;

  @override
  Future<AvatarResult> setGoogleSync(bool enabled) async {
    syncRequests.add(enabled);
    return answer;
  }

  @override
  Future<AvatarResult> remove() async {
    removals++;
    return answer;
  }
}

/// Toasts stay for a few seconds; a test must not end while one is showing.
Future<void> _letToastsLeave(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  group('AvatarController', () {
    late StubServer server;
    late int profileReloads;

    AvatarController controllerWith({
      Future<({String? url})?> Function()? readGooglePhoto,
    }) {
      return AvatarController(
        AvatarRepository(server.dio, storageDio: server.dio),
        readGooglePhoto: readGooglePhoto ?? () async => (url: _googlePhoto),
        onChanged: () => profileReloads++,
      );
    }

    setUp(() {
      server = _server();
      profileReloads = 0;
    });

    test(
      'a photo from the camera or the gallery is uploaded, then put to use',
      () async {
        final result = await controllerWith().upload(
          Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/jpeg',
        );

        expect(result, AvatarResult.changed);
        expect(
          [
            for (final request in server.requests)
              '${request.method} ${request.path}',
          ],
          [
            // Where to put the file, the file itself, then "use it".
            'POST /users/me/avatar/upload',
            'PUT https://storage.test/put-here',
            'PUT /users/me/avatar',
          ],
        );
        expect(server.requests.last.body, {'path': 'u1/new-picture'});
        expect(profileReloads, 1);
      },
    );

    test('ticking "Sync from Google" uses the Google photo', () async {
      expect(await controllerWith().setGoogleSync(true), AvatarResult.changed);

      expect(server.requests.single.path, '/users/me/avatar/google');
      expect(server.requests.single.body, {'photoUrl': _googlePhoto});
    });

    test('unticking it removes the picture', () async {
      expect(await controllerWith().setGoogleSync(false), AvatarResult.changed);

      expect(server.requests.single.method, 'DELETE');
      expect(server.requests.single.path, '/users/me/avatar');
    });

    test(
      'closing the Google picker, or a Google account without a photo, changes nothing',
      () async {
        final cancelled = controllerWith(readGooglePhoto: () async => null);
        final noPhoto = controllerWith(
          readGooglePhoto: () async => (url: null),
        );

        expect(await cancelled.setGoogleSync(true), AvatarResult.cancelled);
        expect(await noPhoto.setGoogleSync(true), AvatarResult.noGooglePhoto);
        expect(server.requests, isEmpty);
        expect(profileReloads, 0);
      },
    );

    test('reports a failed upload and does not reload the profile', () async {
      server = StubServer.always(500);

      final result = await controllerWith().upload(
        Uint8List.fromList([1]),
        mimeType: 'image/png',
      );

      expect(result, AvatarResult.failed);
      expect(profileReloads, 0);
    });
  });

  group('picture options', () {
    Future<_FakeAvatarController> open(
      WidgetTester tester,
      UserProfile profile,
    ) async {
      final controller = _FakeAvatarController();
      await pumpTestApp(
        tester,
        Scaffold(body: AvatarOptionsSheet(profile: profile)),
        overrides: [
          userProfileProvider.overrideWith((ref) async => profile),
          avatarControllerProvider.overrideWithValue(controller),
        ],
      );
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('offer the camera and the gallery to everyone', (tester) async {
      await open(tester, _profile());

      expect(find.text('Take photo'), findsOneWidget);
      expect(find.text('Choose from storage'), findsOneWidget);
      // No Google account to sync with, and no picture to remove.
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.text('Remove photo'), findsNothing);
    });

    testWidgets(
      '"Sync from Google" is a tick box, ticked while the picture is the Google photo',
      (tester) async {
        final controller = await open(
          tester,
          _profile(
            firebaseUid: 'fb1',
            avatarUrl: _googlePhoto,
            avatarFromGoogle: true,
          ),
        );
        final box = tester.widget<CheckboxListTile>(
          find.byType(CheckboxListTile),
        );
        expect(box.value, isTrue);

        await tester.tap(find.text('Sync from Google Account'));
        await tester.pumpAndSettle();

        expect(controller.syncRequests, [false]);
        await _letToastsLeave(tester);
      },
    );

    testWidgets('ticking it turns the sync on', (tester) async {
      final controller = await open(tester, _profile(firebaseUid: 'fb1'));
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );

      await tester.tap(find.text('Sync from Google Account'));
      await tester.pumpAndSettle();

      expect(controller.syncRequests, [true]);
      expect(find.text('Profile picture updated.'), findsOneWidget);
      await _letToastsLeave(tester);
    });

    testWidgets('says so when the picture could not be changed', (
      tester,
    ) async {
      final controller = await open(tester, _profile(firebaseUid: 'fb1'));
      controller.answer = AvatarResult.failed;

      await tester.tap(find.text('Sync from Google Account'));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not change the profile picture. Please try again.'),
        findsOneWidget,
      );
      await _letToastsLeave(tester);
    });

    testWidgets('a picture the user uploaded can be removed', (tester) async {
      final controller = await open(
        tester,
        _profile(avatarUrl: 'https://storage.test/avatars/u1/mine'),
      );

      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();

      expect(controller.removals, 1);
      await _letToastsLeave(tester);
    });
  });

  test('a picture is stored under the right media type', () {
    expect(imageMimeTypeOf('IMG_0001.PNG'), 'image/png');
    expect(imageMimeTypeOf('photo.heic'), 'image/heic');
    expect(imageMimeTypeOf('scan'), 'image/jpeg');
  });
}
