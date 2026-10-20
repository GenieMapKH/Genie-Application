import 'package:flutter/widgets.dart';

/// Calls [onLoadMore] when the scrollable [child] is scrolled near its end,
/// and also when its content is too short to scroll at all, so a short first
/// page cannot leave the rest unread. [enabled] is false while a page is
/// already on its way, or when there is none left.
class LoadMoreOnScroll extends StatelessWidget {
  final bool enabled;
  final VoidCallback onLoadMore;
  final Widget child;

  /// How close to the end, in logical pixels, the next page is asked for:
  /// about a screen ahead, so it is usually there before it is needed.
  static const double threshold = 800;

  const LoadMoreOnScroll({
    super.key,
    required this.enabled,
    required this.onLoadMore,
    required this.child,
  });

  bool _onNotification(Notification notification) {
    final metrics = switch (notification) {
      ScrollNotification(:final metrics) => metrics,
      // Sent after layout when the content changed size: a page arrived.
      ScrollMetricsNotification(:final metrics) => metrics,
      _ => null,
    };
    if (enabled &&
        metrics != null &&
        metrics.axis == Axis.vertical &&
        metrics.extentAfter < threshold) {
      onLoadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<Notification>(
      onNotification: _onNotification,
      child: child,
    );
  }
}
