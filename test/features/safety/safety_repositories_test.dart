import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/chat/data/chat_socket_service.dart';
import 'package:tilomnov/features/chat/models/chat_send_problem.dart';
import 'package:tilomnov/features/safety/data/block_repository.dart';
import 'package:tilomnov/features/safety/data/models/report_reason.dart';
import 'package:tilomnov/features/safety/data/report_repository.dart';

import '../../support/test_app.dart';

void main() {
  group('BlockRepository', () {
    test('blocks, unblocks and reads the status of one person', () async {
      final server = StubServer.always(
        200,
        '{"isBlocked": true, "canMessage": false}',
      );
      final repository = BlockRepository(server.dio);

      final status = await repository.block('u-2');
      await repository.unblock('u-2');
      await repository.fetchStatus('u-2');

      expect(status.isBlocked, isTrue);
      expect(status.canMessage, isFalse);
      expect(server.requests.map((r) => '${r.method} ${r.path}'), [
        'PUT /users/u-2/block',
        'DELETE /users/u-2/block',
        'GET /users/u-2/block',
      ]);
    });

    test('reads the accounts blocked', () async {
      final server = StubServer.always(
        200,
        '[{"id": "u-2", "name": " ", "username": "dara", "avatarUrl": null,'
        ' "blockedAt": "2026-10-24T09:00:00.000Z"}]',
      );

      final blocked = await BlockRepository(server.dio).fetchBlocked();

      expect(blocked.single.id, 'u-2');
      // No name chosen: the username stands in.
      expect(blocked.single.displayName, 'dara');
      expect(blocked.single.blockedAt, DateTime.utc(2026, 10, 24, 9));
    });
  });

  group('ReportRepository', () {
    test('sends the target, reason and trimmed details', () async {
      final server = StubServer.always(201);

      final failure = await ReportRepository(server.dio).submit(
        target: ReportTarget.listing,
        targetId: 'p-1',
        reason: ReportReason.scam,
        details: '  asks for a deposit  ',
      );

      expect(failure, isNull);
      expect(server.requests.single.path, '/reports');
      expect(server.requests.single.body, {
        'targetType': 'listing',
        'targetId': 'p-1',
        'reason': 'scam',
        'details': 'asks for a deposit',
      });
    });

    test('leaves out empty details', () async {
      final server = StubServer.always(201);
      await ReportRepository(server.dio).submit(
        target: ReportTarget.user,
        targetId: 'u-2',
        reason: ReportReason.harassment,
        details: '   ',
      );
      expect(server.requests.single.body, {
        'targetType': 'user',
        'targetId': 'u-2',
        'reason': 'harassment',
      });
    });

    test('says why a report was refused', () async {
      Future<ReportFailure?> answering(int status) =>
          ReportRepository(StubServer.always(status).dio).submit(
            target: ReportTarget.user,
            targetId: 'u-2',
            reason: ReportReason.spam,
          );

      expect(await answering(429), ReportFailure.tooMany);
      expect(await answering(404), ReportFailure.notFound);
      expect(await answering(500), ReportFailure.failed);
    });
  });

  test('every reason offered is one the server knows, per target', () {
    for (final target in ReportTarget.values) {
      final reasons = ReportReason.forTarget(target);
      expect(reasons, isNotEmpty);
      expect(reasons.last, ReportReason.other);
    }
    expect(
      ReportReason.forTarget(ReportTarget.user),
      isNot(contains(ReportReason.duplicate)),
    );
  });

  test('a message refused because of a block is named so', () {
    expect(
      ChatSendException.rejected(
        'You cannot message this person.',
        code: 'blocked',
      ).problem,
      ChatSendProblem.blocked,
    );
    expect(
      ChatSendException.rejected('Something else').problem,
      ChatSendProblem.rejected,
    );
  });
}
