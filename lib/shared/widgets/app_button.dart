import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable, customizable button component designed for Genie with tactile micro-interactions.
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final double height;
  final double? maxWidth;
  final EdgeInsetsGeometry padding;
  final bool isLoading;
  final Widget? icon;
  final TextStyle? textStyle;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF4F5BD5),
    this.textColor = Colors.white,
    this.borderColor,
    this.borderWidth = 2.0,
    this.borderRadius = 10.0,
    this.height = 50.0,
    this.maxWidth = 408.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
    this.isLoading = false,
    this.icon,
    this.textStyle,
  });

  /// Factory for the Primary login button (#4F5BD5 background, white text).
  factory AppButton.primary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    double height = 54.0,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      backgroundColor: const Color(0xFF4F5BD5),
      textColor: Colors.white,
      borderColor: Colors.transparent,
      borderWidth: 2.0,
      height: height,
      isLoading: isLoading,
      icon: icon,
    );
  }

  /// Factory for the Secondary explore button (#FFFFFF background, #E5E7EB border).
  factory AppButton.secondary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    double height = 54.0,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      backgroundColor: Colors.white,
      textColor: const Color(0xFF374151),
      borderColor: const Color(0xFFE5E7EB),
      borderWidth: 2.0,
      height: height,
      isLoading: isLoading,
      icon: icon,
    );
  }

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
    final effectiveBorder = widget.borderColor != null && widget.borderColor != Colors.transparent
        ? Border.all(color: widget.borderColor!, width: widget.borderWidth)
        : null;

    final resolvedTextStyle = widget.textStyle ??
        GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: widget.textColor,
          letterSpacing: -0.2,
        );

    Widget content;
    if (widget.isLoading) {
      content = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(widget.textColor),
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
        color: widget.backgroundColor,
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
