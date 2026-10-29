import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/safety/data/models/report_reason.dart';
import 'package:tilomnov/features/safety/presentation/block_actions.dart';
import 'package:tilomnov/features/safety/presentation/view_models/block_providers.dart';
import 'package:tilomnov/features/safety/presentation/widgets/report_sheet.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/menus/app_menu_item.dart';

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
      itemBuilder: (menuContext) => [
        if (listingId != null)
          appMenuItem(
            menuContext,
            value: _SafetyAction.reportListing,
            icon: Icons.flag_outlined,
            label: l10n.reportListingAction,
          ),
        appMenuItem(
          menuContext,
          value: _SafetyAction.reportPerson,
          icon: Icons.report_outlined,
          label: l10n.reportUserAction,
        ),
        if (isBlocked)
          appMenuItem(
            menuContext,
            value: _SafetyAction.unblock,
            icon: Icons.lock_open_outlined,
            label: l10n.unblockAction,
          )
        else
          appMenuItem(
            menuContext,
            value: _SafetyAction.block,
            icon: Icons.block,
            label: l10n.blockAction,
            danger: true,
          ),
      ],
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
