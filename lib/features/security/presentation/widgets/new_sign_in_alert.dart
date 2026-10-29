import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/security/data/models/device_session.dart';
import 'package:tilomnov/features/security/presentation/screens/devices_page.dart';
import 'package:tilomnov/features/security/presentation/view_models/security_providers.dart';
import 'package:tilomnov/features/security/presentation/widgets/device_session_tile.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';

/// Tells the user when another device has signed in to their account.
///
/// Draws nothing. Placed once on the main screen, it looks at the device
/// list when the user signs in and each time the app comes back to the
/// front, and shows a dialog for devices the user has not been told about.
class NewSignInAlert extends ConsumerStatefulWidget {
  const NewSignInAlert({super.key});

  @override
  ConsumerState<NewSignInAlert> createState() => _NewSignInAlertState();
}

class _NewSignInAlertState extends ConsumerState<NewSignInAlert>
    with WidgetsBindingObserver {
  /// True from the moment a check starts until its dialog is closed.
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final userId = ref.read(userProfileProvider).valueOrNull?.id;
    if (userId == null || _isBusy || !mounted) return;

    _isBusy = true;
    try {
      final detector = ref.read(newSignInDetectorProvider);
      final newDevices = await detector.check(userId);
      if (newDevices.isEmpty || !mounted) return;

      final review = await _show(newDevices);
      await detector.acknowledge(userId, newDevices);
      if (review == true && mounted) {
        await context.pushPage(const DevicesPage());
      }
    } catch (e) {
      // Offline, or signed out meanwhile: looked at again next time.
      AppLogger.error('Could not check for new sign-ins', e);
    } finally {
      _isBusy = false;
    }
  }

  /// True when the user wants to review the devices.
  Future<bool?> _show(List<DeviceSession> devices) {
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        final colors = dialogContext.colors;
        return AlertDialog(
          icon: Icon(Icons.gpp_maybe_outlined, color: colors.danger, size: 32),
          title: Text(l10n.newSignInTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.newSignInMessage,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                for (final device in devices) ...[
                  DeviceSessionTile(session: device),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.newSignInWasMe),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.newSignInReview),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Signing in (or switching account) is a moment to look, too.
    ref.listen(
      userProfileProvider.select((profile) => profile.valueOrNull?.id),
      (_, userId) {
        if (userId != null) _check();
      },
    );
    return const SizedBox.shrink();
  }
}
