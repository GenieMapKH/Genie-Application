import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/home/utils/map/markers/marker_cache.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Counts renders and hands out a fresh bitmap for each one.
class _Renderer {
  int count = 0;

  Future<BitmapDescriptor> call() async {
    count++;
    await Future<void>.delayed(Duration.zero);
    return BitmapDescriptor.defaultMarkerWithHue(count.toDouble());
  }
}

void main() {
  test('markers asked for at the same moment share one render', () async {
    final cache = MarkerCache();
    final render = _Renderer();

    final icons = await Future.wait([
      cache.get('110 m', render.call),
      cache.get('110 m', render.call),
    ]);

    expect(render.count, 1);
    expect(identical(icons[0], icons[1]), isTrue);
  });

  test('drops the least recently used bitmap past its limit', () async {
    final cache = MarkerCache(maxEntries: 2);
    final render = _Renderer();

    await cache.get('a', render.call);
    await cache.get('b', render.call);
    await cache.get('a', render.call); // "b" is now the oldest
    await cache.get('c', render.call);

    await cache.get('a', render.call);
    expect(render.count, 3);
    await cache.get('b', render.call);
    expect(render.count, 4);
  });

  test('a failed render is tried again next time', () async {
    final cache = MarkerCache();
    final render = _Renderer();

    await expectLater(
      cache.get('x', () => Future.error(StateError('no canvas'))),
      throwsStateError,
    );
    await cache.get('x', render.call);

    expect(render.count, 1);
  });
}
