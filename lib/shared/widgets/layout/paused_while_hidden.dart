import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds [builder] while shown, and while hidden (inside a disabled
/// [TickerMode], as a kept tab page is) keeps what it built last.
///
/// Watch the data the page shows through the `ref` given to [builder]. A
/// hidden build makes no `ref.watch`, and Riverpod then stops the widget
/// listening, so changes to that data no longer rebuild the hidden page.
/// Shown again, it builds once with the data as it is by then.
///
/// The providers keep their state while unwatched, unless they are
/// autoDispose: one watched only from here would be disposed while hidden.
class PausedWhileHidden extends ConsumerStatefulWidget {
  final Widget Function(BuildContext context, WidgetRef ref) builder;

  const PausedWhileHidden({super.key, required this.builder});

  @override
  ConsumerState<PausedWhileHidden> createState() => _PausedWhileHiddenState();
}

class _PausedWhileHiddenState extends ConsumerState<PausedWhileHidden> {
  Widget? _built;

  @override
  Widget build(BuildContext context) {
    final shown = TickerMode.valuesOf(context).enabled;
    final built = _built;
    if (!shown && built != null) return built;
    return _built = widget.builder(context, ref);
  }
}
