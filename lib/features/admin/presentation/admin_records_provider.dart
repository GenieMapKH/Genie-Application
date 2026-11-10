import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/admin/data/admin_record.dart';
import 'package:tilomnov/features/admin/presentation/admin_dashboard_provider.dart';
import 'package:tilomnov/shared/utils/paged_list.dart';

typedef AdminRecordsFilter = ({
  String section,
  String? tier,
  String? query,
  String? purpose,
});

final adminRecordsProvider = AsyncNotifierProvider.autoDispose
    .family<AdminRecordsNotifier, PagedList<AdminRecord>, AdminRecordsFilter>(
      AdminRecordsNotifier.new,
    );

class AdminRecordsNotifier
    extends
        AutoDisposeFamilyAsyncNotifier<
          PagedList<AdminRecord>,
          AdminRecordsFilter
        > {
  int? _nextOffset;
  int _generation = 0;

  @override
  Future<PagedList<AdminRecord>> build(AdminRecordsFilter arg) async {
    final generation = ++_generation;
    _nextOffset = null;
    ref.onDispose(() => _generation++);
    final page = await ref
        .watch(adminDashboardRepositoryProvider)
        .records(
          arg.section,
          tier: arg.tier,
          query: arg.query,
          purpose: arg.purpose,
        );
    if (generation == _generation) _nextOffset = page.nextOffset;
    return PagedList(items: page.items, hasMore: page.nextOffset != null);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    final offset = _nextOffset;
    if (current == null || offset == null || current.loadingMore) return;
    final generation = _generation;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await ref
          .read(adminDashboardRepositoryProvider)
          .records(
            arg.section,
            offset: offset,
            tier: arg.tier,
            query: arg.query,
            purpose: arg.purpose,
          );
      if (generation != _generation) return;
      _nextOffset = page.nextOffset;
      state = AsyncData(
        current.appended(
          page.items,
          hasMore: page.nextOffset != null,
          idOf: (item) => item.id,
        ),
      );
    } catch (_) {
      if (generation != _generation) return;
      state = AsyncData(current);
      rethrow;
    }
  }
}
