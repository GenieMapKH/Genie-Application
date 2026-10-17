import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/core/theme/app_colors.dart';

/// The look a button takes from the theme when no colours are given.
enum _AppButtonKind { primary, secondary }

/// A reusable, customizable button component designed for Genie with tactile micro-interactions.
///
/// Colours left out come from the theme, so the button follows light and
/// dark mode: brand background with white text, or for [AppButton.secondary]
/// a surface background with a border.
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final double height;
  final double? maxWidth;
  final EdgeInsetsGeometry padding;
  final bool isLoading;
  final Widget? icon;
  final TextStyle? textStyle;
  final _AppButtonKind _kind;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth = 2.0,
    this.borderRadius = 10.0,
    this.height = 50.0,
    this.maxWidth = 408.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
    this.isLoading = false,
    this.icon,
    this.textStyle,
  }) : _kind = _AppButtonKind.primary;

  /// The main action of a screen: brand background, white text.
  const AppButton.primary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 54.0,
  }) : backgroundColor = null,
       textColor = null,
       borderColor = null,
       borderWidth = 2.0,
       borderRadius = 10.0,
       maxWidth = 408.0,
       padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
       textStyle = null,
       _kind = _AppButtonKind.primary;

  /// A quieter action next to a primary one: surface background, outlined.
  const AppButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 54.0,
  }) : backgroundColor = null,
       textColor = null,
       borderColor = null,
       borderWidth = 2.0,
       borderRadius = 10.0,
       maxWidth = 408.0,
       padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
       textStyle = null,
       _kind = _AppButtonKind.secondary;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isLoading && widget.onPressed != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isSecondary = widget._kind == _AppButtonKind.secondary;
    final backgroundColor =
        widget.backgroundColor ??
        (isSecondary ? colors.surface : colors.primary);
    final textColor =
        widget.textColor ??
        (isSecondary ? colors.textSecondary : colors.onPrimary);
    final borderColor =
        widget.borderColor ?? (isSecondary ? colors.border : null);

    final effectiveBorder =
        borderColor != null && borderColor != Colors.transparent
        ? Border.all(color: borderColor, width: widget.borderWidth)
        : null;

    final resolvedTextStyle =
        widget.textStyle ??
        GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: -0.2,
        );

    Widget content;
    if (widget.isLoading) {
      content = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    } else if (widget.icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.icon!,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.text,
              style: resolvedTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      content = Text(
        widget.text,
        style: resolvedTextStyle,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      );
    }

    final buttonWidget = Container(
      constraints: widget.maxWidth != null
          ? BoxConstraints(maxWidth: widget.maxWidth!)
          : null,
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: effectiveBorder,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Padding(
            padding: widget.padding,
            child: Center(child: content),
          ),
        ),
      ),
    );

    return RepaintBoundary(
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutCubic,
        child: buttonWidget,
      ),
    );
  }
}
