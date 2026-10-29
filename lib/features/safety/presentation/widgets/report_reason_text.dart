import 'package:tilomnov/features/safety/data/models/report_reason.dart';
import 'package:tilomnov/l10n/generated/app_localizations.dart';

/// The words for [reason].
String reportReasonText(AppLocalizations l10n, ReportReason reason) {
  return switch (reason) {
    ReportReason.scam => l10n.reportReasonScam,
    ReportReason.misleading => l10n.reportReasonMisleading,
    ReportReason.unavailable => l10n.reportReasonUnavailable,
    ReportReason.duplicate => l10n.reportReasonDuplicate,
    ReportReason.harassment => l10n.reportReasonHarassment,
    ReportReason.impersonation => l10n.reportReasonImpersonation,
    ReportReason.inappropriate => l10n.reportReasonInappropriate,
    ReportReason.spam => l10n.reportReasonSpam,
    ReportReason.other => l10n.reportReasonOther,
  };
}
