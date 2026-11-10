import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import '../data/admin_operations.dart';
import '../data/admin_operations_repository.dart';

final adminOperationsRepositoryProvider = Provider(
  (ref) => AdminOperationsRepository(ref.watch(apiClientProvider)),
);
final adminRotationJobProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(adminOperationsRepositoryProvider).rotationJob(),
);
final adminDeploymentsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(adminOperationsRepositoryProvider).deployments(),
);
final adminLogsProvider = AsyncNotifierProvider.autoDispose
    .family<AdminLogsNotifier, AdminLogPage, String>(AdminLogsNotifier.new);

class AdminLogsNotifier
    extends AutoDisposeFamilyAsyncNotifier<AdminLogPage, String> {
  int _generation = 0;
  @override
  Future<AdminLogPage> build(String arg) {
    _generation++;
    ref.onDispose(() => _generation++);
    return ref.watch(adminOperationsRepositoryProvider).logs(arg);
  }

  Future<void> refresh({bool older = false}) async {
    final current = state.valueOrNull;
    if (current == null ||
        current.busy ||
        (older && current.nextCursor == null)) {
      return;
    }
    final generation = _generation;
    state = AsyncData(current.copyWith(busy: true, refreshFailed: false));
    try {
      final page = await ref
          .read(adminOperationsRepositoryProvider)
          .logs(arg, cursor: older ? current.nextCursor : null);
      if (generation != _generation) return;
      if (!older) {
        state = AsyncData(page);
        return;
      }
      final entries = {
        for (final row in current.entries) row.id: row,
        for (final row in page.entries) row.id: row,
      }.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = AsyncData(
        AdminLogPage(
          status: page.status,
          checkedAt: page.checkedAt,
          environment: page.environment,
          entries: entries,
          nextCursor: page.nextCursor,
        ),
      );
    } catch (_) {
      if (generation == _generation) {
        state = AsyncData(current.copyWith(busy: false, refreshFailed: true));
      }
    }
  }
}
