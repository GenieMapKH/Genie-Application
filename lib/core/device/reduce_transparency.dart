import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';

/// iOS's Reduce Transparency setting, which Flutter does not report: when on,
/// glass gives way to solid surfaces. Other systems have no such setting.
class ReduceTransparency {
  static const _channel = MethodChannel('tilomnov/accessibility');

  const ReduceTransparency();

  Future<bool> read() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    try {
      return await _channel.invokeMethod<bool>('reduceTransparency') ?? false;
    } on PlatformException catch (e, st) {
      AppLogger.error('Could not read Reduce Transparency', e, st);
      return false;
    } on MissingPluginException catch (e, st) {
      AppLogger.error('Reduce Transparency is not wired up natively', e, st);
      return false;
    }
  }
}

/// Whether Reduce Transparency is on. Read before the first frame (see
/// `main.dart`) and again whenever the app returns to the foreground, since
/// the setting is changed outside the app.
final reduceTransparencyProvider =
    StateNotifierProvider<ReduceTransparencyNotifier, bool>(
      (ref) => ReduceTransparencyNotifier(const ReduceTransparency()),
    );

class ReduceTransparencyNotifier extends StateNotifier<bool> {
  final ReduceTransparency _reader;
  late final AppLifecycleListener _lifecycle;

  ReduceTransparencyNotifier(this._reader, {bool initial = false})
    : super(initial) {
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  Future<void> _refresh() async {
    final reduce = await _reader.read();
    if (mounted) state = reduce;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }
}
