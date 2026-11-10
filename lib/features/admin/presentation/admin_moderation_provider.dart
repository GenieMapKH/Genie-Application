import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_moderation_repository.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';

final adminModerationRepositoryProvider = Provider(
  (ref) => AdminModerationRepository(ref.watch(apiClientProvider)),
);
typedef ReportFilter = ({String? type, String? id, String? query});
final adminReportsProvider = AsyncNotifierProvider.autoDispose
    .family<AdminReportsNotifier, ModerationPage, ReportFilter>(
      AdminReportsNotifier.new,
    );

class AdminReportsNotifier
    extends AutoDisposeFamilyAsyncNotifier<ModerationPage, ReportFilter> {
  bool _loadingMore = false;
  int _generation = 0;
  @override
  Future<ModerationPage> build(ReportFilter arg) {
    _generation++;
    ref.onDispose(() => _generation++);
    return ref
        .watch(adminModerationRepositoryProvider)
        .reports(type: arg.type, id: arg.id, query: arg.query);
  }

  Future<void> loadMore() async {
    final page = state.valueOrNull;
    if (state.isLoading ||
        page == null ||
        page.nextOffset == null ||
        _loadingMore) {
      return;
    }
    _loadingMore = true;
    final generation = _generation;
    try {
      final next = await ref
          .read(adminModerationRepositoryProvider)
          .reports(
            type: arg.type,
            id: arg.id,
            query: arg.query,
            offset: page.nextOffset!,
          );
      if (generation != _generation) return;
      final seen = page.items
          .map((row) => row.values['targetId'] ?? row.id)
          .toSet();
      state = AsyncData((
        items: [
          ...page.items,
          ...next.items.where(
            (row) => seen.add(row.values['targetId'] ?? row.id),
          ),
        ],
        nextOffset: next.nextOffset,
        reportCount: next.reportCount,
        reporterCount: next.reporterCount,
      ));
    } finally {
      _loadingMore = false;
    }
  }
}
