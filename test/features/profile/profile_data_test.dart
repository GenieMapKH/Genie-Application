import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/data/repositories/user_repository.dart';
import 'package:genie/features/profile/presentation/view_models/profile_edit_controller.dart';

import '../../support/test_app.dart';

const _profileJson =
    '{"id":"u1","email":"sokha@example.com","phone":null,"username":"sokha",'
    '"name":"Sokha Chan","firstName":"Sokha","lastName":null,"sex":"female",'
    '"role":"user","createdAt":"2026-01-01T00:00:00.000Z","firebaseUid":"fb1",'
    '"avatarUrl":null}';

void main() {
  group('UserProfile', () {
    test('reads the handle, the name and the personal details', () {
      final profile = UserProfile.fromJson({
        'id': 'u1',
        'username': 'sokha',
        'name': 'Sokha Chan',
        'firstName': 'Sokha',
        'sex': 'female',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'firebaseUid': 'fb1',
      });

      expect(profile.username, 'sokha');
      expect(profile.name, 'Sokha Chan');
      expect(profile.firstName, 'Sokha');
      expect(profile.lastName, isNull);
      expect(profile.sex, Sex.female);
      expect(profile.signsInWithGoogle, isTrue);
    });

    test('ignores a sex this version does not know', () {
      expect(Sex.fromApi('robot'), isNull);
      expect(Sex.fromApi(null), isNull);
    });

    test('is called by the name, else the handle, phone or email', () {
      UserProfile profile({String? name, String? username, String? phone}) =>
          UserProfile(
            id: 'u1',
            role: 'user',
            createdAt: DateTime(2026),
            name: name,
            username: username,
            phone: phone,
            email: 'sokha@example.com',
          );

      expect(profile(name: 'Sokha', username: 'sk').displayName, 'Sokha');
      expect(profile(username: 'sk', phone: '012').displayName, 'sk');
      expect(profile(phone: '012').displayName, '012');
      expect(profile().displayName, 'sokha');
      expect(profile(name: '', username: 'sk').displayName, 'sk');
    });
  });

  group('UserRepository.updateField', () {
    test('sends only the changed field, under the name the API uses', () async {
      final server = StubServer.always(200, _profileJson);

      final profile = await UserRepository(
        server.dio,
      ).updateField(ProfileField.displayName, 'Sokha Chan');

      final request = server.requests.single;
      expect((request.method, request.path), ('PATCH', '/users/me'));
      expect(request.body, {'name': 'Sokha Chan'});
      expect(profile.name, 'Sokha Chan');
    });

    test('clears a field with an explicit null', () async {
      final server = StubServer.always(200, _profileJson);

      await UserRepository(server.dio).updateField(ProfileField.lastName, null);

      expect(server.requests.single.body, {'lastName': null});
    });

    test('tells a taken value from an invalid one', () async {
      Future<void> updateAnswering(int status) => UserRepository(
        StubServer.always(status).dio,
      ).updateField(ProfileField.username, 'sokha');

      await expectLater(
        updateAnswering(409),
        throwsA(isA<ProfileValueTakenException>()),
      );
      await expectLater(
        updateAnswering(400),
        throwsA(isA<ProfileValueInvalidException>()),
      );
      await expectLater(updateAnswering(500), throwsA(isA<DioException>()));
    });
  });

  group('ProfileEditController', () {
    late StubServer server;
    late int reloads;
    late ProfileEditController controller;

    void serverAnswers(int status) {
      server = StubServer.always(status, _profileJson);
      reloads = 0;
      controller = ProfileEditController(
        UserRepository(server.dio),
        onSaved: () => reloads++,
      );
    }

    setUp(() => serverAnswers(200));

    test('saves a username in lowercase and reloads the profile', () async {
      final result = await controller.save(ProfileField.username, ' Sokha_99 ');

      expect(result, ProfileSaveResult.saved);
      expect(server.requests.single.body, {'username': 'sokha_99'});
      expect(reloads, 1);
    });

    test('refuses a badly formed username without asking the server', () async {
      for (final username in ['ab', 'has space', 'សុខា', 'a' * 31, '', null]) {
        expect(
          await controller.save(ProfileField.username, username),
          ProfileSaveResult.invalid,
          reason: '$username',
        );
      }
      expect(server.requests, isEmpty);
      expect(reloads, 0);
    });

    test('lets a name be anything short enough, or be cleared', () async {
      expect(
        await controller.save(ProfileField.displayName, 'សុខា ចាន់'),
        ProfileSaveResult.saved,
      );
      expect(
        await controller.save(ProfileField.displayName, 'x' * 61),
        ProfileSaveResult.invalid,
      );
      expect(
        await controller.save(ProfileField.firstName, '   '),
        ProfileSaveResult.saved,
      );
      expect(server.requests.last.body, {'firstName': null});
    });

    test('does not let the phone number be emptied', () async {
      expect(
        await controller.save(ProfileField.phone, ''),
        ProfileSaveResult.invalid,
      );
      expect(server.requests, isEmpty);
    });

    test('reports a username someone else has', () async {
      serverAnswers(409);

      expect(
        await controller.save(ProfileField.username, 'sokha'),
        ProfileSaveResult.taken,
      );
      expect(reloads, 0);
    });

    test('reports a server failure', () async {
      serverAnswers(500);

      expect(
        await controller.save(ProfileField.displayName, 'Sokha'),
        ProfileSaveResult.failed,
      );
    });
  });
}
