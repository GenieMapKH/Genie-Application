import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/auth/presentation/widgets/sign_in_required_dialog.dart';
import 'package:genie/features/safety/data/models/report_reason.dart';
import 'package:genie/features/safety/data/report_repository.dart';
import 'package:genie/features/safety/presentation/view_models/report_providers.dart';
import 'package:genie/features/safety/presentation/widgets/report_reason_text.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/app_popup.dart';

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
  final sent = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
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

    return Padding(
      // Above the keyboard while the note is typed.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.target == ReportTarget.listing
                    ? l10n.reportListingTitle
                    : l10n.reportUserTitle,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.reportHelp,
                style: GoogleFonts.inter(fontSize: 13, color: colors.textMuted),
              ),
              const SizedBox(height: 8),
              RadioGroup<ReportReason>(
                groupValue: _reason,
                onChanged: (reason) => setState(() => _reason = reason),
                child: Column(
                  children: [
                    for (final reason in ReportReason.forTarget(widget.target))
                      RadioListTile<ReportReason>(
                        value: reason,
                        contentPadding: EdgeInsets.zero,
                        activeColor: colors.accent,
                        title: Text(
                          reportReasonText(l10n, reason),
                          style: GoogleFonts.inter(
                            fontSize: 15,
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
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: l10n.reportDetailsHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _reason == null || _sending ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.danger,
                  foregroundColor: colors.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _sending
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.reportSend),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
