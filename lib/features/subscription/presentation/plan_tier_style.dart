import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/subscription/domain/plan_tier.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// The look of one tier where it is celebrated: the metal of the profile
/// frame and member badge, and the current plan's card. Everyday controls
/// stay in the app's own style and only take [PlanTierAccent.accentOn].
class PlanTierStyle {
  /// Bright metal, swept around the profile frame and across the badge.
  final List<Color> metal;

  /// Deep version of the metal, behind white text (the current plan card).
  final List<Color> deep;

  /// Soft light around the frame.
  final Color glow;

  /// Text and icons on top of [metal].
  final Color onMetal;

  final IconData icon;

  const PlanTierStyle({
    required this.metal,
    required this.deep,
    required this.glow,
    required this.onMetal,
    required this.icon,
  });

  static PlanTierStyle of(PlanTier tier) => switch (tier) {
    PlanTier.free => _free,
    PlanTier.silver => _silver,
    PlanTier.gold => _gold,
    PlanTier.diamond => _diamond,
  };

  LinearGradient get metalGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: metal,
  );

  LinearGradient get deepGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: deep,
  );

  static const _free = PlanTierStyle(
    metal: [Color(0xFF2A4B78), Color(0xFF142B4A)],
    deep: [Color(0xFF1E3D66), Color(0xFF0E1F36)],
    glow: Color(0xFF1E3D66),
    onMetal: Color(0xFFFFFFFF),
    icon: Icons.home_work_rounded,
  );

  static const _silver = PlanTierStyle(
    metal: [
      Color(0xFFFFFFFF),
      Color(0xFFC9D1DB),
      Color(0xFF8C96A5),
      Color(0xFFE9EDF2),
      Color(0xFFA7B0BD),
      Color(0xFFFFFFFF),
    ],
    deep: [Color(0xFF7A8595), Color(0xFF2E3540)],
    glow: Color(0xFFAEB8C6),
    onMetal: Color(0xFF2B323C),
    icon: Icons.military_tech_rounded,
  );

  static const _gold = PlanTierStyle(
    metal: [
      Color(0xFFFFF4C7),
      Color(0xFFE9C062),
      Color(0xFFB8862B),
      Color(0xFFFFE39A),
      Color(0xFFC99A3E),
      Color(0xFFFFF4C7),
    ],
    deep: [Color(0xFFC0912F), Color(0xFF5A3E10)],
    glow: Color(0xFFE2B455),
    onMetal: Color(0xFF3F2C0A),
    icon: Icons.workspace_premium_rounded,
  );

  static const _diamond = PlanTierStyle(
    metal: [
      Color(0xFFE0F7FF),
      Color(0xFF7FD3F7),
      Color(0xFFA78BFA),
      Color(0xFFF0ABFC),
      Color(0xFF67E8F9),
      Color(0xFFE0F7FF),
    ],
    deep: [Color(0xFF5B5BEA), Color(0xFF0E7490)],
    glow: Color(0xFF8B9CF7),
    onMetal: Color(0xFF1E1B4B),
    icon: Icons.diamond_rounded,
  );
}

extension PlanTierAccent on PlanTier {
  /// One quiet colour that tells the tiers apart on everyday screens (the
  /// plan icon), readable on the surfaces of both themes. Free takes the
  /// app's own accent; Gold is the brand gold.
  Color accentOn(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (this) {
      PlanTier.free => colors.accent,
      PlanTier.silver =>
        dark ? const Color(0xFFB8C1CD) : const Color(0xFF7A8595),
      PlanTier.gold => colors.highlight,
      PlanTier.diamond =>
        dark ? const Color(0xFF8FA8FF) : const Color(0xFF5B74E8),
    };
  }
}

/// White on a deep [fill], the app's navy ink on a light one.
Color readableOn(Color fill) =>
    ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
    ? Colors.white
    : const Color(0xFF0F1F36);

extension PlanTierLabel on PlanTier {
  String label(AppLocalizations l10n) => switch (this) {
    PlanTier.free => l10n.planFree,
    PlanTier.silver => l10n.planSilver,
    PlanTier.gold => l10n.planGold,
    PlanTier.diamond => l10n.planDiamond,
  };
}
