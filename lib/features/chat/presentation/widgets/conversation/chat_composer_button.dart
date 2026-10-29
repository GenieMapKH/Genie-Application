import 'package:flutter/material.dart';

/// A button of the message bar. Its touch area is larger than what it
/// draws, and takes taps anywhere inside it, so a thumb near the icon does
/// not miss it.
class ChatComposerButton extends StatelessWidget {
  /// The touch area of the buttons beside the message field.
  static const outerSize = 52.0;

  /// The touch area of the buttons inside the message field.
  static const innerSize = 48.0;

  final String label;
  final VoidCallback? onTap;
  final double size;
  final Widget child;

  const ChatComposerButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}
