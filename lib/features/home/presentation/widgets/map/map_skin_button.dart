import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/home/presentation/providers/map_state_provider.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/buttons/tactile_button.dart';

/// Previews the skin that the next tap will select.
class MapSkinButton extends StatelessWidget {
  final MapSkin currentSkin;
  final VoidCallback onPressed;

  const MapSkinButton({
    super.key,
    required this.currentSkin,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final next = currentSkin.next;
    final label = switch (next) {
      MapSkin.defaultMap => context.l10n.mapSkinDefault,
      MapSkin.satellite => context.l10n.mapSkinSatellite,
    };
    final asset = switch (next) {
      MapSkin.defaultMap => 'assets/images/homescreen/mapDefault.png',
      MapSkin.satellite => 'assets/images/homescreen/mapSatellite.png',
    };
    return Tooltip(
      message: context.l10n.mapSkinSwitch(label),
      child: FocusableActionDetector(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onPressed();
              return null;
            },
          ),
        },
        child: TactileButton(
          onPressed: onPressed,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
              image: DecorationImage(
                image: AssetImage(asset),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
