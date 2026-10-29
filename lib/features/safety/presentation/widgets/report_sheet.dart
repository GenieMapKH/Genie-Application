import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/auth/presentation/widgets/sign_in_required_dialog.dart';
import 'package:tilomnov/features/safety/data/models/report_reason.dart';
import 'package:tilomnov/features/safety/data/report_repository.dart';
import 'package:tilomnov/features/safety/presentation/view_models/report_providers.dart';
import 'package:tilomnov/features/safety/presentation/widgets/report_reason_text.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/dialogs/app_dialog.dart';

/// The longest note the server keeps.
const _maxDetails = 1000;

/// Asks why [targetId] is reported, then sends it. A guest is asked to sign
/// in first.
Future<void> showReportSheet(
  BuildContext context,
  WidgetRef ref, {
  required ReportTarget target,
  required String targetId,
}) async {
  if (!requireSignIn(context, ref)) return;
  final sent = await AppDialog.show<bool>(
    context,
    builder: (_) => _ReportSheet(target: target, targetId: targetId),
  );
  if (sent == true && context.mounted) {
    AppPopup.showSuccess(context, context.l10n.reportSent);
  }
}

class _ReportSheet extends ConsumerStatefulWidget {
  final ReportTarget target;
  final String targetId;

  const _ReportSheet({required this.target, required this.targetId});

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _details = TextEditingController();
  ReportReason? _reason;
  bool _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    setState(() => _sending = true);
    final failure = await ref
        .read(reportRepositoryProvider)
        .submit(
          target: widget.target,
          targetId: widget.targetId,
          reason: reason,
          details: _details.text,
        );
    if (!mounted) return;
    if (failure == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _sending = false);
    final l10n = context.l10n;
    AppPopup.showError(context, switch (failure) {
      ReportFailure.tooMany => l10n.reportTooMany,
      ReportFailure.notFound => l10n.reportTargetGone,
      ReportFailure.failed => l10n.reportFailed,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return AppDialog(
      icon: Icons.flag_rounded,
      tone: AppDialogTone.danger,
      title: widget.target == ReportTarget.listing
          ? l10n.reportListingTitle
          : l10n.reportUserTitle,
      message: l10n.reportHelp,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RadioGroup<ReportReason>(
            groupValue: _reason,
            onChanged: (reason) => setState(() => _reason = reason),
            child: Column(
              children: [
                for (final reason in ReportReason.forTarget(widget.target))
                  RadioListTile<ReportReason>(
                    value: reason,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: colors.danger,
                    title: Text(
                      reportReasonText(l10n, reason),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _details,
            maxLength: _maxDetails,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            style: GoogleFonts.inter(fontSize: 14, color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.reportDetailsHint,
              filled: true,
              fillColor: colors.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      primaryLabel: l10n.reportSend,
      onPrimary: _reason == null ? null : _send,
      primaryBusy: _sending,
      secondaryLabel: l10n.commonCancel,
    );
  }
}
