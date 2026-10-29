import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/shared/utils/paged_list.dart';

/// What the My Properties screen shows: the user's own listings loaded so
/// far, and how many they have in each status (all of them, loaded or not),
/// for its tabs.
class OwnListings {
  final PagedList<PropertyModel> page;
  final Map<String, int> countByStatus;

  const OwnListings({
    this.page = const PagedList(),
    this.countByStatus = const {},
  });

  List<PropertyModel> get items => page.items;

  /// How many listings are in [status] (`Active`, `Draft`, ...).
  int count(String status) => countByStatus[status] ?? 0;

  OwnListings copyWith({
    PagedList<PropertyModel>? page,
    Map<String, int>? countByStatus,
  }) {
    return OwnListings(
      page: page ?? this.page,
      countByStatus: countByStatus ?? this.countByStatus,
    );
  }

  /// Listing [id] moved to [status], or removed when [status] is null: the
  /// list and the counts as they will be once the server agrees. Unchanged
  /// when the listing is not loaded.
  OwnListings withStatus(String id, String? status) {
    final index = items.indexWhere((p) => p.id == id);
    if (index < 0) return this;
    final old = items[index];

    final counts = {...countByStatus};
    counts[old.status] = (counts[old.status] ?? 1) - 1;
    if (counts[old.status]! <= 0) counts.remove(old.status);
    if (status != null) counts[status] = (counts[status] ?? 0) + 1;

    final updated = [...items];
    if (status == null) {
      updated.removeAt(index);
    } else {
      updated[index] = old.copyWith(status: status);
    }
    return OwnListings(
      page: page.copyWith(items: updated),
      countByStatus: counts,
    );
  }
}
