import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/safety/data/models/report_reason.dart';
import 'package:genie/features/safety/presentation/block_actions.dart';
import 'package:genie/features/safety/presentation/view_models/block_providers.dart';
import 'package:genie/features/safety/presentation/widgets/report_sheet.dart';
import 'package:genie/l10n/l10n.dart';

enum _SafetyAction { reportListing, reportPerson, block, unblock }

/// The "more" menu wherever a person (and maybe their listing) is shown:
/// report the listing, report the person, block or unblock them.
class SafetyMenuButton extends ConsumerWidget {
  final String userId;
  final String userName;

  /// Set on a listing: "Report listing" comes first.
  final String? listingId;
  final Color? iconColor;

  const SafetyMenuButton({
    super.key,
    required this.userId,
    required this.userName,
    this.listingId,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // A guest is asked to sign in when they pick something; nothing is read.
    final status = ref.watch(isSignedInProvider)
        ? ref.watch(blockStatusProvider(userId)).valueOrNull
        : null;
    final isBlocked = status?.isBlocked ?? false;

    return PopupMenuButton<_SafetyAction>(
      tooltip: l10n.safetyMore,
      icon: Icon(Icons.more_vert, color: iconColor ?? context.colors.textMuted),
      onSelected: (action) => _run(context, ref, action),
      itemBuilder: (_) => [
        if (listingId != null)
          _item(
            _SafetyAction.reportListing,
            Icons.flag_outlined,
            l10n.reportListingAction,
          ),
        _item(
          _SafetyAction.reportPerson,
          Icons.report_outlined,
          l10n.reportUserAction,
        ),
        if (isBlocked)
          _item(
            _SafetyAction.unblock,
            Icons.lock_open_outlined,
            l10n.unblockAction,
          )
        else
          _item(_SafetyAction.block, Icons.block, l10n.blockAction),
      ],
    );
  }

  PopupMenuItem<_SafetyAction> _item(
    _SafetyAction action,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: action,
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  void _run(BuildContext context, WidgetRef ref, _SafetyAction action) {
    switch (action) {
      case _SafetyAction.reportListing:
        showReportSheet(
          context,
          ref,
          target: ReportTarget.listing,
          targetId: listingId!,
        );
      case _SafetyAction.reportPerson:
        showReportSheet(
          context,
          ref,
          target: ReportTarget.user,
          targetId: userId,
        );
      case _SafetyAction.block || _SafetyAction.unblock:
        setBlocked(
          context,
          ref,
          userId: userId,
          name: userName,
          blocked: action == _SafetyAction.block,
        );
    }
  }
}
