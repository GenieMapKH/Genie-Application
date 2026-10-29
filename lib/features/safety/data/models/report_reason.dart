/// What a report is about.
enum ReportTarget {
  listing('listing'),
  user('user');

  /// As the server names it.
  final String wire;

  const ReportTarget(this.wire);
}

/// Why something is reported. [wire] is the server's value
/// (`REPORT_REASONS`); the screen picks the words.
enum ReportReason {
  scam('scam'),
  misleading('misleading'),
  unavailable('unavailable'),
  duplicate('duplicate'),
  harassment('harassment'),
  impersonation('impersonation'),
  inappropriate('inappropriate'),
  spam('spam'),
  other('other');

  final String wire;

  const ReportReason(this.wire);

  /// The reasons that make sense for [target], most common first.
  static List<ReportReason> forTarget(ReportTarget target) => switch (target) {
    ReportTarget.listing => const [
      scam,
      misleading,
      unavailable,
      duplicate,
      inappropriate,
      spam,
      other,
    ],
    ReportTarget.user => const [
      scam,
      harassment,
      impersonation,
      inappropriate,
      spam,
      other,
    ],
  };
}
