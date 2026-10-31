import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';

import 'dart:async';

/// The look of a popup: green, red, or the brand's navy and gold.
enum AppPopupTone { success, error, info }

class AppPopup {
  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, AppPopupTone.success);

  static void showError(BuildContext context, String message) =>
      _show(context, message, AppPopupTone.error);

  static void showInfo(BuildContext context, String message) =>
      _show(context, message, AppPopupTone.info);

  /// The red "No internet connection", with a retry button calling
  /// [onRetry]. [message] is that sentence in the user's language.
  static void showOffline(
    BuildContext context,
    String message, {
    required VoidCallback onRetry,
  }) {
    showOn(
      Overlay.of(context, rootOverlay: true),
      message,
      tone: AppPopupTone.error,
      icon: Icons.wifi_off_rounded,
      onRetry: onRetry,
    );
  }

  /// Shows on [overlay] itself, for the app shell: it sits above the
  /// Navigator, so it has no overlay to find from its own context. [icon]
  /// replaces the tone's own; with [onRetry] it has a retry button, which
  /// also closes it. Returns a call that hides the popup early.
  static VoidCallback showOn(
    OverlayState overlay,
    String message, {
    required AppPopupTone tone,
    IconData? icon,
    VoidCallback? onRetry,
  }) {
    final hide = ValueNotifier(false);
    late OverlayEntry overlayEntry;
    final (toneIcon, iconColor, backgroundColor, borderColor) = _style(tone);

    overlayEntry = OverlayEntry(
      builder: (context) => _TopToastWidget(
        message: message,
        icon: icon ?? toneIcon,
        iconColor: iconColor,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        hideRequest: hide,
        onRetry: onRetry,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);
    return () => hide.value = true;
  }

  static void _show(BuildContext context, String message, AppPopupTone tone) {
    showOn(Overlay.of(context, rootOverlay: true), message, tone: tone);
  }

  /// Icon, icon colour, background and border of each tone.
  static (IconData, Color, Color, Color) _style(AppPopupTone tone) =>
      switch (tone) {
        AppPopupTone.success => (
          Icons.check_circle_rounded,
          const Color(0xFF10B981), // Emerald Green
          const Color(0xFF064E3B), // Very dark emerald
          const Color(0xFF059669).withValues(alpha: 0.3),
        ),
        AppPopupTone.error => (
          Icons.error_rounded,
          const Color(0xFFEF4444), // Rose Red
          const Color(0xFF4C0519), // Very dark rose
          const Color(0xFFE11D48).withValues(alpha: 0.3),
        ),
        AppPopupTone.info => (
          Icons.info_rounded,
          AppColors.light.highlight, // Brand gold
          AppColors.light.primary, // Brand navy
          AppColors.light.highlight.withValues(alpha: 0.3),
        ),
      };
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;

  /// Turns true when the popup should leave before its time is up.
  final ValueListenable<bool> hideRequest;

  /// When set, a retry button at the end; tapping it closes the popup too.
  final VoidCallback? onRetry;
  final VoidCallback onDismiss;

  const _TopToastWidget({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.hideRequest,
    required this.onDismiss,
    this.onRetry,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _timer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    widget.hideRequest.addListener(_dismiss);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    _timer = Timer(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    // A tap, a swipe, the timer and [hideRequest] may all ask: leave once.
    if (!mounted || _dismissing) return;
    _dismissing = true;
    _timer?.cancel();
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    widget.hideRequest.removeListener(_dismiss);
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta! < -2) {
                _dismiss();
              }
            },
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.borderColor, width: 1.5),
                // Removed shadow per user request
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (widget.onRetry case final onRetry?)
                    IconButton(
                      tooltip: context.l10n.commonRetry,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: widget.iconColor,
                      ),
                      onPressed: () {
                        _dismiss();
                        onRetry();
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
