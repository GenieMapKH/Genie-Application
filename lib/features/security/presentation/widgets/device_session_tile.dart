import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/security/data/models/device_session.dart';
import 'package:genie/l10n/l10n.dart';

/// "Active now", "Last used 5 minutes ago", ... for [session], as of [now].
String lastUsedLabel(
  AppLocalizations l10n,
  DeviceSession session,
  DateTime now,
) {
  final ago = now.difference(session.lastUsedAt);
  // The device looking at the list is in use by definition.
  if (session.isCurrent || ago.inMinutes < 1) return l10n.devicesActiveNow;
  if (ago.inHours < 1) return l10n.devicesLastUsedMinutes(ago.inMinutes);
  if (ago.inDays < 1) return l10n.devicesLastUsedHours(ago.inHours);
  return l10n.devicesLastUsedDays(ago.inDays);
}

/// One signed-in device: what it is, where it is, when it was last used,
/// and, with [canSignOut], a button to sign it out (never on the device that
/// is looking).
class DeviceSessionTile extends StatelessWidget {
  final DeviceSession session;

  /// False where the device is only shown, or may not be signed out from here.
  final bool canSignOut;

  /// Null while a sign-out is running, which disables the button.
  final VoidCallback? onSignOut;

  const DeviceSessionTile({
    super.key,
    required this.session,
    this.canSignOut = false,
    this.onSignOut,
  });

  bool get _isPhone {
    final platform = session.platform?.toLowerCase() ?? '';
    return platform.contains('android') || platform.contains('ios');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final signedIn = DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    ).format(session.signedInAt.toLocal());
    final details = [
      ?session.platform,
      session.location ?? l10n.devicesUnknownLocation,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: session.isCurrent ? colors.accent : colors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _isPhone ? Icons.smartphone : Icons.computer,
            size: 28,
            color: colors.textMuted,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.deviceName ?? l10n.devicesUnknownDevice,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (session.isCurrent) ...[
                  const SizedBox(height: 4),
                  _ThisDeviceBadge(label: l10n.devicesThisDevice),
                ],
                const SizedBox(height: 6),
                for (final line in [
                  details,
                  lastUsedLabel(l10n, session, DateTime.now()),
                  l10n.devicesSignedInOn(signedIn),
                ])
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      line,
                      style: TextStyle(fontSize: 13, color: colors.textMuted),
                    ),
                  ),
              ],
            ),
          ),
          if (canSignOut && !session.isCurrent)
            TextButton(
              onPressed: onSignOut,
              style: TextButton.styleFrom(foregroundColor: colors.danger),
              child: Text(l10n.devicesSignOut),
            ),
        ],
      ),
    );
  }
}

class _ThisDeviceBadge extends StatelessWidget {
  final String label;

  const _ThisDeviceBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.accent,
        ),
      ),
    );
  }
}
