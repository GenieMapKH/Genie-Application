import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A modern, reusable text input field component designed for Genie.
/// Features smooth animated focus glow, interactive border states, and custom error messaging.
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final Widget? topTrailingWidget;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final double borderRadius;
  final double? maxWidth;

  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.prefixIcon,
    this.topTrailingWidget,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.borderRadius = 10.0,
    this.maxWidth = 408.0,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
    }
  }

  void _handleFocusChange() {
    if (mounted && _isFocused != _focusNode.hasFocus) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    const errorColor = Color(0xFFDC2626);
    const primaryColor = Color(0xFF4F5BD5);
    const defaultBorderColor = Color(0xFFE5E7EB);

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(
        color: hasError ? errorColor : defaultBorderColor,
        width: hasError ? 1.8 : 1.5,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(
        color: hasError ? errorColor : primaryColor,
        width: 1.8,
      ),
    );

    final inputBox = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: hasError
                      ? const Color(0x1ADC2626)
                      : const Color(0x1F4F5BD5),
                  blurRadius: 10.0,
                  spreadRadius: 1.0,
                  offset: const Offset(0, 2),
                ),
              ]
            : const [],
      ),
      child: TextFormField(
        focusNode: _focusNode,
        controller: widget.controller,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        validator: widget.validator,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        enabled: widget.enabled,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF111827),
        ),
        cursorColor: hasError ? errorColor : primaryColor,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: hasError ? const Color(0xFFE57373) : const Color(0xFF9CA3AF),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 14.0,
          ),
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          border: border,
          enabledBorder: border,
          focusedBorder: focusedBorder,
          errorBorder: border,
          focusedErrorBorder: focusedBorder,
          errorStyle: const TextStyle(height: 0, fontSize: 0),
        ),
      ),
    );

    final errorRow = AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: hasError
          ? Padding(
              padding: const EdgeInsets.only(top: 6.0, left: 2.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 14.0, color: errorColor),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      widget.errorText!,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: errorColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );

    Widget fullWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null || widget.topTrailingWidget != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.label != null)
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isFocused
                        ? (hasError ? errorColor : primaryColor)
                        : const Color(0xFF1E293B),
                  ),
                  child: Text(widget.label!),
                )
              else
                const SizedBox.shrink(),
              ?widget.topTrailingWidget,
            ],
          ),
          const SizedBox(height: 8),
        ],
        inputBox,
        errorRow,
      ],
    );

    if (widget.maxWidth != null) {
      fullWidget = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth!),
        child: fullWidget,
      );
    }

    return fullWidget;
  }
}
