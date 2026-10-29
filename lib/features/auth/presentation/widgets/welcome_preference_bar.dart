import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/settings/providers/app_settings_providers.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// Language and theme switches for the welcome screen, so they can be changed
/// before signing in. Shares the providers behind the Settings page.
///
/// Icon only: one frosted capsule holding a flag that flips to the
/// other language and a sun/moon that swaps the theme.
class WelcomePreferenceBar extends ConsumerWidget {
  const WelcomePreferenceBar({super.key});

  static const double _slot = 40;
  static const _duration = Duration(milliseconds: 380);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = Localizations.localeOf(context).languageCode;
    final next = AppLanguages.all.firstWhere(
      (locale) => locale.languageCode != current,
      orElse: () => AppLanguages.english,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: isDark ? 0.55 : 0.85),
            borderRadius: BorderRadius.circular(_slot),
            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PreferenceButton(
                tooltip: AppLanguages.nativeName(next),
                onTap: () => ref.read(localeProvider.notifier).select(next),
                child: _FlagCoin(languageCode: current),
              ),
              Container(
                width: 1,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: colors.divider,
              ),
              _PreferenceButton(
                tooltip: isDark
                    ? context.l10n.appearanceLight
                    : context.l10n.appearanceDark,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .select(isDark ? ThemeMode.light : ThemeMode.dark),
                child: _ThemeGlyph(isDark: isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round, borderless tap target with a soft ink splash.
class _PreferenceButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  const _PreferenceButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: WelcomePreferenceBar._slot,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// The current language's flag as a small rounded card, flipping on change.
class _FlagCoin extends StatelessWidget {
  static const _flags = {
    'en': 'assets/icons/flag_en.svg',
    'km': 'assets/icons/flag_km.svg',
  };

  final String languageCode;

  const _FlagCoin({required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedSwitcher(
      duration: WelcomePreferenceBar._duration,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY((1 - animation.value) * math.pi / 2),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        ),
      ),
      child: Container(
        key: ValueKey(languageCode),
        width: 26,
        height: 18,
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SvgPicture.asset(
            _flags[languageCode] ?? _flags['en']!,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

/// A warm sun in light mode and a cool moon in dark mode, spun on change.
class _ThemeGlyph extends StatelessWidget {
  static const _sun = Color(0xFFF5A524);
  static const _moon = Color(0xFFA9B8FF);

  final bool isDark;

  const _ThemeGlyph({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: WelcomePreferenceBar._duration,
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, animation) => RotationTransition(
        turns: Tween(begin: -0.35, end: 0.0).animate(animation),
        child: ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
      ),
      child: Icon(
        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        key: ValueKey(isDark),
        size: 22,
        color: isDark ? _moon : _sun,
      ),
    );
  }
}
