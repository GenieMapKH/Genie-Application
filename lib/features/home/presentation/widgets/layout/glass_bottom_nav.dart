import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/core/theme/app_motion.dart';
import 'package:tilomnov/features/home/presentation/providers/main_nav_provider.dart';
import 'package:tilomnov/features/home/presentation/widgets/glass/glass_surface.dart';
import 'package:tilomnov/features/home/presentation/widgets/glass/selection_droplet_painter.dart';
import 'package:tilomnov/features/home/presentation/widgets/layout/nav_tabs.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/buttons/tactile_button.dart';
import 'package:tilomnov/shared/widgets/media/tinted_svg.dart';

/// The bottom navigation as a floating glass capsule, for phones whose own
/// interface is glass. A drop of tinted glass marks the open tab and slides
/// to the next one on a spring, stretching as it travels; the picked icon
/// gives a small bounce.
///
/// It fills the same slot as the regular bar, so nothing above it moves; the
/// map shows around the capsule.
class GlassBottomNav extends ConsumerStatefulWidget {
  const GlassBottomNav({super.key});

  /// The height of the regular bar (`PropertyCarousel.bottomNavHeight`).
  static const slotHeight = 98.0;

  static const _capsuleHeight = 62.0;
  static const _sideMargin = 12.0;

  /// Six tabs of a comfortable width; wider screens centre the capsule.
  static const _maxWidth = 480.0;

  /// Clear of the home indicator or system buttons, yet inside the slot.
  static double _bottomGap(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    const roomLeft = slotHeight - _capsuleHeight;
    return (safeBottom - 10).clamp(10.0, roomLeft - 4);
  }

  /// How far the capsule's bottom edge is above the bottom of the screen.
  static double capsuleBottomOf(BuildContext context) => _bottomGap(context);

  /// The capsule's size on a screen [screenWidth] wide; it is centred.
  static Size capsuleSizeFor(double screenWidth) =>
      Size(math.min(screenWidth - 2 * _sideMargin, _maxWidth), _capsuleHeight);

  @override
  ConsumerState<GlassBottomNav> createState() => _GlassBottomNavState();
}

class _GlassBottomNavState extends ConsumerState<GlassBottomNav>
    with SingleTickerProviderStateMixin {
  /// The droplet's place, counted in tabs. Unbounded so its spring may
  /// overshoot the picked tab a little.
  late final AnimationController _droplet = AnimationController.unbounded(
    vsync: this,
    value: ref.read(mainNavProvider).currentIndex.toDouble(),
  );

  @override
  void dispose() {
    _droplet.dispose();
    super.dispose();
  }

  void _moveDropletTo(int index) {
    if (AppMotion.reduceMotionOf(context)) {
      _droplet.value = index.toDouble();
      return;
    }
    _droplet.animateWith(
      SpringSimulation(
        AppMotion.selection,
        _droplet.value,
        index.toDouble(),
        _droplet.velocity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainNavProvider).currentIndex;
    ref.listen(
      mainNavProvider.select((nav) => nav.currentIndex),
      (_, index) => _moveDropletTo(index),
    );
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    const radius = BorderRadius.all(
      Radius.circular(GlassBottomNav._capsuleHeight / 2),
    );

    return SizedBox(
      height: GlassBottomNav.slotHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            GlassBottomNav._sideMargin,
            0,
            GlassBottomNav._sideMargin,
            GlassBottomNav._bottomGap(context),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: GlassBottomNav._maxWidth,
            ),
            child: SizedBox(
              height: GlassBottomNav._capsuleHeight,
              child: GlassSurface(
                borderRadius: radius,
                child: CustomPaint(
                  painter: SelectionDropletPainter(
                    position: _droplet,
                    count: mainNavTabs.length,
                    color: colors.primary.withValues(alpha: dark ? 0.26 : 0.13),
                    rim: Colors.white.withValues(alpha: dark ? 0.18 : 0.6),
                  ),
                  child: Row(
                    children: [
                      for (final tab in mainNavTabs)
                        Expanded(
                          child: _GlassNavItem(
                            tab: tab,
                            selected: tab.index == currentIndex,
                            onPressed: () =>
                                selectMainTab(context, ref, tab.index),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One tab in the capsule: its icon and name, tinted when open, with a
/// spring bounce at the moment it is picked.
class _GlassNavItem extends StatefulWidget {
  final NavTab tab;
  final bool selected;
  final VoidCallback onPressed;

  const _GlassNavItem({
    required this.tab,
    required this.selected,
    required this.onPressed,
  });

  @override
  State<_GlassNavItem> createState() => _GlassNavItemState();
}

class _GlassNavItemState extends State<_GlassNavItem>
    with SingleTickerProviderStateMixin {
  /// Where the bounce starts: the icon dips, then springs past its size.
  static const _bounceFrom = 0.82;

  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );

  @override
  void didUpdateWidget(_GlassNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) _bounce();
  }

  void _bounce() {
    if (AppMotion.reduceMotionOf(context)) return;
    _scale.animateWith(SpringSimulation(AppMotion.bouncy, _bounceFrom, 1, 0));
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = widget.selected ? colors.primaryStrong : colors.textMuted;

    return Semantics(
      selected: widget.selected,
      child: TactileButton(
        pressedScale: 0.9,
        onPressed: widget.onPressed,
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: color),
          duration: AppMotion.fade,
          curve: Curves.easeOut,
          builder: (context, color, _) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scale,
                child: NavUnreadBadge(
                  tabIndex: widget.tab.index,
                  icon: TintedSvg(
                    widget.tab.iconAsset,
                    width: 24,
                    height: 24,
                    color: color ?? colors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  widget.tab.label(context.l10n),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: widget.selected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
