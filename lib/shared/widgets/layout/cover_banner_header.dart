import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tilomnov/core/theme/app_colors.dart';

/// Top of a profile screen: a coloured cover band behind the status bar,
/// with the back arrow (and [title]) on it, the round [avatar] overlapping
/// its lower edge on the left and [trailing] (a button) on the right.
class CoverBannerHeader extends StatelessWidget {
  final Widget avatar;

  /// The radius [avatar] is drawn at; it gets a ring of the page colour.
  final double avatarRadius;
  final Widget? trailing;
  final String? title;

  /// What the back arrow does. Defaults to leaving the screen.
  final VoidCallback? onBackPressed;

  const CoverBannerHeader({
    super.key,
    required this.avatar,
    required this.avatarRadius,
    this.trailing,
    this.title,
    this.onBackPressed,
  });

  static const double _bannerHeight = 112;
  static const double _ringWidth = 4;

  /// Room kept for [trailing]: a gap below the band, then a button.
  static const double _trailingGap = 12;
  static const double _trailingHeight = 44;

  @override
  Widget build(BuildContext context) {
    final bannerHeight = MediaQuery.paddingOf(context).top + _bannerHeight;
    final avatarSize = (avatarRadius + _ringWidth) * 2;
    final trailing = this.trailing;

    final belowBanner = trailing == null
        ? avatarSize / 2
        : max(avatarSize / 2, _trailingGap + _trailingHeight);

    return SizedBox(
      height: bannerHeight + belowBanner,
      child: Stack(
        children: [
          _CoverBanner(
            height: bannerHeight,
            title: title,
            onBackPressed: onBackPressed,
          ),
          Positioned(
            left: 12,
            top: bannerHeight - avatarSize / 2,
            child: Container(
              padding: const EdgeInsets.all(_ringWidth),
              decoration: BoxDecoration(
                color: context.colors.background,
                shape: BoxShape.circle,
              ),
              child: avatar,
            ),
          ),
          if (trailing != null)
            Positioned(
              left: avatarSize + 24,
              right: 16,
              // Clear of the band, beside the lower half of the picture.
              top: bannerHeight + _trailingGap,
              height: _trailingHeight,
              child: Align(alignment: Alignment.centerRight, child: trailing),
            ),
        ],
      ),
    );
  }
}

/// The coloured band, with two soft rings for texture and the back arrow.
class _CoverBanner extends StatelessWidget {
  final double height;
  final String? title;
  final VoidCallback? onBackPressed;

  const _CoverBanner({required this.height, this.title, this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title = this.title;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primary, colors.accent],
          ),
        ),
        child: Stack(
          children: [
            const _Ring(right: -40, top: -50, size: 180),
            const _Ring(right: 70, bottom: -70, size: 120),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    _BannerBackButton(
                      onPressed:
                          onBackPressed ?? () => Navigator.maybePop(context),
                    ),
                    Expanded(
                      child: title == null
                          ? const SizedBox.shrink()
                          : Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    // Balances the back arrow so the title stays centred.
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double? top;
  final double? right;
  final double? bottom;
  final double size;

  const _Ring({this.top, this.right, this.bottom, required this.size});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 18,
          ),
        ),
      ),
    );
  }
}

class _BannerBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BannerBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 40,
          child: Icon(
            Icons.arrow_back,
            size: 22,
            color: Colors.white,
            semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
          ),
        ),
      ),
    );
  }
}
