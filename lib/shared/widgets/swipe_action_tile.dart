import 'package:flutter/material.dart';

import 'package:genie/core/theme/app_colors.dart';

/// One button revealed by swiping a [SwipeActionTile].
class SwipeAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const SwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });
}

/// A list row that slides left to reveal [actions] behind its right edge.
/// A tap on the row while it is open closes it instead of opening the row.
class SwipeActionTile extends StatefulWidget {
  final Widget child;
  final List<SwipeAction> actions;

  const SwipeActionTile({
    super.key,
    required this.child,
    required this.actions,
  });

  static const double actionWidth = 80;

  @override
  State<SwipeActionTile> createState() => _SwipeActionTileState();
}

class _SwipeActionTileState extends State<SwipeActionTile>
    with SingleTickerProviderStateMixin {
  /// 0 is closed, 1 is fully open.
  late final _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  double get _openWidth => widget.actions.length * SwipeActionTile.actionWidth;
  bool get _isOpen => _slide.value > 0;

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _slide.value -= (details.primaryDelta ?? 0) / _openWidth;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final open = velocity < -300 || (velocity <= 300 && _slide.value > 0.5);
    open ? _slide.forward() : _slide.reverse();
  }

  void _run(SwipeAction action) {
    _slide.reverse();
    action.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final action in widget.actions)
                  _ActionButton(action: action, onPressed: () => _run(action)),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _slide,
            builder: (context, child) => Transform.translate(
              offset: Offset(-_slide.value * _openWidth, 0),
              child: child,
            ),
            child: ColoredBox(
              color: context.colors.background,
              child: AnimatedBuilder(
                animation: _slide,
                builder: (context, child) => _isOpen
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _slide.reverse,
                        child: AbsorbPointer(child: child),
                      )
                    : child!,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final SwipeAction action;
  final VoidCallback onPressed;

  const _ActionButton({required this.action, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: SwipeActionTile.actionWidth,
      child: Material(
        color: action.color,
        child: InkWell(
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                action.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
