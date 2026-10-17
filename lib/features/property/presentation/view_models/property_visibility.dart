/// Who can see a listing, as its owner chooses it.
enum PropertyVisibility {
  /// Status 'Active': on the map for everyone.
  public,

  /// Status 'Draft': only the owner sees it.
  draft,

  /// Status 'Sold': taken off the map.
  sold;

  /// The visibility of a listing [status]; null for one in between
  /// (being paid for, expired).
  static PropertyVisibility? of(String status) => switch (status) {
    'Active' => public,
    'Draft' => draft,
    'Sold' => sold,
    _ => null,
  };
}

/// The server call that moves a listing from one visibility to another.
enum VisibilityChange { publish, relist, unpublish, markSold }

/// How to move a listing of [status] to [target], or null when the server
/// does not allow it (or it is already there). Mirrors the server's rules:
/// only a public listing can be marked sold; a sold one is relisted.
VisibilityChange? visibilityChange(String status, PropertyVisibility target) {
  if (PropertyVisibility.of(status) == target) return null;
  return switch (target) {
    PropertyVisibility.public => switch (status) {
      'Draft' || 'Expired' => VisibilityChange.publish,
      'Sold' => VisibilityChange.relist,
      _ => null,
    },
    PropertyVisibility.draft => switch (status) {
      'Active' || 'Sold' || 'Expired' => VisibilityChange.unpublish,
      _ => null,
    },
    PropertyVisibility.sold =>
      status == 'Active' ? VisibilityChange.markSold : null,
  };
}
