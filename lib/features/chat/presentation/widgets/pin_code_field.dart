import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:genie/core/theme/app_colors.dart';

/// Six boxes for a 6-digit PIN, typed on the number pad. Digits show as
/// dots. [onCompleted] runs when the sixth digit is typed.
///
/// [hasError] turns the boxes red; changing [shakeCount] shakes them once,
/// so the same error typed twice is still noticed.
class PinCodeField extends StatefulWidget {
  static const length = 6;

  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;
  final bool enabled;
  final bool hasError;
  final int shakeCount;
  final bool autofocus;

  const PinCodeField({
    super.key,
    required this.controller,
    this.onCompleted,
    this.enabled = true,
    this.hasError = false,
    this.shakeCount = 0,
    this.autofocus = true,
  });

  @override
  State<PinCodeField> createState() => _PinCodeFieldState();
}

class _PinCodeFieldState extends State<PinCodeField>
    with SingleTickerProviderStateMixin {
  final _focusNode = FocusNode();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focusNode.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(PinCodeField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
    if (old.shakeCount != widget.shakeCount) _shake.forward(from: 0);
    // Back from checking a PIN: ready for the next one at once.
    if (!old.enabled && widget.enabled) _focusNode.requestFocus();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onTextChanged(String text) {
    if (text.length == PinCodeField.length) widget.onCompleted?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final typed = widget.controller.text.length;

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(sin(_shake.value * pi * 6) * 10 * (1 - _shake.value), 0),
        child: child,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // As wide as there is room for, up to comfortable boxes.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 312),
            child: Row(
              children: [
                for (var i = 0; i < PinCodeField.length; i++)
                  Expanded(
                    child: _PinBox(
                      filled: i < typed,
                      active:
                          widget.enabled &&
                          _focusNode.hasFocus &&
                          i == min(typed, PinCodeField.length - 1),
                      hasError: widget.hasError,
                      enabled: widget.enabled,
                    ),
                  ),
              ],
            ),
          ),
          // The real input, invisible over the boxes: tapping them opens
          // the number pad, and paste and autofill keep working.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(PinCodeField.length),
                ],
                onChanged: _onTextChanged,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinBox extends StatelessWidget {
  final bool filled;
  final bool active;
  final bool hasError;
  final bool enabled;

  const _PinBox({
    required this.filled,
    required this.active,
    required this.hasError,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderColor = hasError
        ? colors.danger
        : active
        ? colors.primary
        : colors.border;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: AspectRatio(
        aspectRatio: 44 / 52,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: enabled ? colors.surface : colors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: active ? 2 : 1.5),
          ),
          alignment: Alignment.center,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            scale: filled ? 1 : 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasError ? colors.danger : colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
