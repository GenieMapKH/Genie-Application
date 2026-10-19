import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:genie/core/theme/app_colors.dart';

/// Swipes a message sideways to reply to it: the other person's to the
/// right, the user's own ([towardsLeft]) to the left. Past [_threshold] a
/// reply arrow shows, the phone ticks, and letting go replies. The message
/// slides back either way.
class SwipeToReply extends StatefulWidget {
  static const _threshold = 56.0;
  static const _maxOffset = 80.0;

  final Widget child;
  final bool towardsLeft;

  /// Null turns swiping off.
  final VoidCallback? onReply;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.towardsLeft,
    this.onReply,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  late final AnimationController _offset = AnimationController(
    vsync: this,
    upperBound: SwipeToReply._maxOffset,
    duration: const Duration(milliseconds: 180),
  );

  bool get _armed => _offset.value >= SwipeToReply._threshold;

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final delta = widget.towardsLeft ? -details.delta.dx : details.delta.dx;
    final wasArmed = _armed;
    // Harder to pull the further it goes.
    final resistance = 1 - _offset.value / SwipeToReply._maxOffset;
    _offset.value = max(0, _offset.value + delta * max(resistance, 0.15));
    if (_armed && !wasArmed) HapticFeedback.selectionClick();
  }

  void _onDragEnd(DragEndDetails details) {
    if (_armed) widget.onReply?.call();
    _offset.animateTo(0, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onReply == null) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: () => _offset.animateTo(0),
      child: AnimatedBuilder(
        animation: _offset,
        child: widget.child,
        builder: (context, child) {
          final progress = (_offset.value / SwipeToReply._threshold).clamp(
            0.0,
            1.0,
          );
          final direction = widget.towardsLeft ? -1.0 : 1.0;
          return Stack(
            clipBehavior: Clip.none,
            alignment: widget.towardsLeft
                ? Alignment.centerRight
                : Alignment.centerLeft,
            children: [
              if (progress > 0)
                Opacity(
                  opacity: progress,
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * progress,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: context.colors.border,
                      child: Icon(
                        Icons.reply,
                        size: 18,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(direction * _offset.value, 0),
                child: child,
              ),
            ],
          );
        },
      ),
    );
  }
}
