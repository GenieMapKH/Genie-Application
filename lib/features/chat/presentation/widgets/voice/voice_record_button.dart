import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The microphone of the message bar. A tap opens the recording bar; held
/// down, it records until released, which sends, and sliding the finger
/// left past [cancelDistance] throws the recording away.
///
/// The widget must stay in the tree while held (it is keyed by its parent),
/// or the release would never reach it.
class VoiceRecordButton extends StatefulWidget {
  /// Pressed this long, a press is a hold rather than a tap.
  static const holdDelay = Duration(milliseconds: 250);

  /// How far left a held finger slides to cancel.
  static const cancelDistance = 120.0;

  final String label;

  /// Touched anywhere in a square this wide, larger than the 44 it draws.
  final double touchSize;

  final VoidCallback? onTap;
  final VoidCallback? onHoldStart;

  /// The hold is over: released ([cancelled] false, send), or slid away or
  /// interrupted by the system ([cancelled] true, throw away).
  final void Function({required bool cancelled})? onHoldEnd;

  const VoiceRecordButton({
    super.key,
    required this.label,
    this.touchSize = 44,
    this.onTap,
    this.onHoldStart,
    this.onHoldEnd,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton> {
  Timer? _holdTimer;
  Offset? _downAt;
  bool _holding = false;

  void _onDown(PointerDownEvent event) {
    if (_downAt != null) return; // One finger at a time.
    _downAt = event.position;
    _holdTimer = Timer(VoiceRecordButton.holdDelay, _startHold);
  }

  void _startHold() {
    if (widget.onHoldStart == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _holding = true);
    widget.onHoldStart!();
  }

  void _onMove(PointerMoveEvent event) {
    final downAt = _downAt;
    if (!_holding || downAt == null) return;
    if (downAt.dx - event.position.dx > VoiceRecordButton.cancelDistance) {
      _endHold(cancelled: true);
    }
  }

  void _onUp(PointerUpEvent event) {
    if (_holding) {
      _endHold(cancelled: false);
    } else if (_downAt != null) {
      _reset();
      widget.onTap?.call();
    }
  }

  void _onCancel(PointerCancelEvent event) {
    if (_holding) {
      _endHold(cancelled: true);
    } else {
      _reset();
    }
  }

  void _endHold({required bool cancelled}) {
    _reset();
    widget.onHoldEnd?.call(cancelled: cancelled);
  }

  void _reset() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _downAt = null;
    if (_holding && mounted) setState(() => _holding = false);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      onTap: widget.onTap,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: _onCancel,
        child: SizedBox.square(
          dimension: widget.touchSize,
          child: Center(
            child: AnimatedScale(
              scale: _holding ? 1.35 : 1,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: SvgPicture.asset(
                'assets/icons/chat_voice.svg',
                width: 44,
                height: 44,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
