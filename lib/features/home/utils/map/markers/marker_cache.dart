import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Rendered marker bitmaps by key.
///
/// It keeps the render itself, not its result, so markers asked for at the
/// same moment (a page of identical price tags, two equal edge lengths) share
/// one bitmap. The map compares markers by their bitmap, so sharing lets it
/// skip them on the next pass instead of sending them again.
///
/// With [maxEntries], the least recently used bitmap is dropped past that
/// many. A render that fails is not kept, so the next request tries again.
class MarkerCache {
  final int? maxEntries;
  final Map<String, Future<BitmapDescriptor>> _renders = {};

  MarkerCache({this.maxEntries});

  Future<BitmapDescriptor> get(
    String key,
    Future<BitmapDescriptor> Function() render,
  ) {
    final cached = _renders.remove(key);
    if (cached != null) return _renders[key] = cached;

    final limit = maxEntries;
    if (limit != null && _renders.length >= limit) {
      _renders.remove(_renders.keys.first);
    }

    final rendering = render();
    rendering.then<void>(
      (_) {},
      onError: (Object _) {
        _renders.remove(key);
      },
    );
    return _renders[key] = rendering;
  }
}
