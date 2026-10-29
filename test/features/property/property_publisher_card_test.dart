import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/follow/data/follow_repository.dart';
import 'package:tilomnov/features/follow/presentation/view_models/follow_providers.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_publisher_opener.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/sections/property_publisher_card.dart';

import '../../support/test_app.dart';

final _listing = PropertyModel.fromJson({
  'id': 'p-1',
  'title': 'Riverside condo',
  'price': '120000',
  'propertyType': 'Condo',
  'status': 'Active',
  'createdAt': '2026-01-01T00:00:00.000Z',
  'user': {
    'id': 'owner-1',
    'name': 'Sokha Realty',
    'username': 'sokha',
    'createdAt': '2014-03-02T00:00:00.000Z',
  },
});

/// Answers follow calls as the server would: following adds one follower.
StubServer _followApi() {
  var following = false;
  return StubServer((request) {
    if (request.method == 'PUT') following = true;
    if (request.method == 'DELETE') following = false;
    return (
      200,
      '{"followerCount": ${following ? 13 : 12}, "followingCount": 3, '
          '"isFollowing": $following}',
    );
  });
}

Future<List<PropertyPublisher>> _pump(
  WidgetTester tester, {
  required StubServer server,
  bool signedIn = true,
  bool isOwner = false,
}) async {
  final opened = <PropertyPublisher>[];
  await pumpTestApp(
    tester,
    Scaffold(
      body: SingleChildScrollView(
        child: PropertyPublisherCard(property: _listing, isOwner: isOwner),
      ),
    ),
    overrides: [
      followRepositoryProvider.overrideWithValue(FollowRepository(server.dio)),
      propertyPublisherOpenerProvider.overrideWithValue(
        (context, publisher) async => opened.add(publisher),
      ),
      signedInOverride(signedIn: signedIn),
    ],
  );
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  testWidgets('shows who posted it, and View Profile opens their profile', (
    tester,
  ) async {
    final opened = await _pump(tester, server: _followApi());

    expect(find.text('Listed by'), findsOneWidget);
    expect(find.text('Sokha Realty'), findsOneWidget);
    expect(find.text('@sokha'), findsOneWidget);
    expect(find.textContaining('Member since March 2014'), findsOneWidget);
    expect(find.textContaining('12 Followers'), findsOneWidget);

    await tester.tap(find.text('View Profile'));
    await tester.pump();
    expect(opened.single.userId, 'owner-1');
    expect(opened.single.name, 'Sokha Realty');
  });

  testWidgets('Follow follows them and counts the new follower', (
    tester,
  ) async {
    final server = _followApi();
    await _pump(tester, server: server);

    await tester.tap(find.text('Follow'));
    await tester.pumpAndSettle();

    expect(
      server.requests.where(
        (r) => r.method == 'PUT' && r.path.endsWith('/users/owner-1/follow'),
      ),
      hasLength(1),
    );
    expect(find.text('Following'), findsOneWidget);
    expect(find.textContaining('13 Followers'), findsOneWidget);
  });

  testWidgets('a guest sees Follow, without counts, and is not followed', (
    tester,
  ) async {
    final server = _followApi();
    await _pump(tester, server: server, signedIn: false);

    expect(find.text('Follow'), findsOneWidget);
    expect(find.textContaining('Followers'), findsNothing);
    expect(server.requests, isEmpty);
  });

  testWidgets('the owner can view their profile but not follow themselves', (
    tester,
  ) async {
    await _pump(tester, server: _followApi(), isOwner: true);

    expect(find.text('View Profile'), findsOneWidget);
    expect(find.text('Follow'), findsNothing);
  });

  testWidgets('when following could not be read, Follow shows and retries', (
    tester,
  ) async {
    var reads = 0;
    final server = StubServer((request) {
      // The first read fails; the retry and the follow answer.
      if (request.method == 'GET' && reads++ == 0) return (500, '{}');
      return (
        200,
        '{"followerCount": 13, "followingCount": 3, "isFollowing": '
            '${request.method == 'PUT'}}',
      );
    });
    await _pump(tester, server: server);

    expect(find.text('Follow'), findsOneWidget);

    await tester.tap(find.text('Follow'));
    await tester.pumpAndSettle();

    expect(server.requests.where((r) => r.method == 'GET'), hasLength(2));
    expect(server.requests.where((r) => r.method == 'PUT'), hasLength(1));
    expect(find.text('Following'), findsOneWidget);
  });
}
