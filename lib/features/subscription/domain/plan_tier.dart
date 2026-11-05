/// The subscription level of an account. Paid tiers raise how many
/// listings may be published at once and give the profile picture a frame.
enum PlanTier {
  free,
  silver,
  gold,
  diamond;

  /// The tier the server names (`"silver"`, `"GOLD"` …); [free] for an
  /// unknown or missing one, so an older server leaves everyone on Free.
  static PlanTier fromApi(Object? value) {
    if (value is! String) return free;
    final name = value.toLowerCase();
    return values.where((tier) => tier.name == name).firstOrNull ?? free;
  }

  bool get isPaid => this != free;
}
