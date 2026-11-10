import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A tab of the My Properties screen: the listing statuses it lists.
enum OwnListingsTab {
  active(['Active']),
  pending(['Pending']),

  /// Expired listings are off the map and can be published again, as a
  /// draft can, so they wait here.
  draft(['Draft', 'Expired']),
  sold(['Sold']);

  final List<String> statuses;

  const OwnListingsTab(this.statuses);

  /// Whether a listing of [status] is listed in this tab.
  bool lists(String status) => statuses.contains(status);

  /// How many listings this tab lists, given the count per status.
  int countIn(Map<String, int> countByStatus) =>
      statuses.fold(0, (sum, status) => sum + (countByStatus[status] ?? 0));
}

/// The My Properties tab shown: the list reads only its listings.
final ownListingsTabProvider = StateProvider<OwnListingsTab>(
  (ref) => OwnListingsTab.active,
);
