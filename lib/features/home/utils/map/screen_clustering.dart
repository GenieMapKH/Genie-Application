import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tilomnov/features/home/utils/map/layers/layer_geometry.dart';
import 'package:tilomnov/features/home/utils/map/map_camera_focus.dart';

/// Map items close enough on screen to be drawn as a single marker.
class ScreenCluster {
  /// Indices into the list of positions that was clustered.
  final List<int> indices;

  /// The members' positions; the cluster marker sits at their average.
  final List<LatLng> points;

  const ScreenCluster(this.indices, this.points);

  LatLng get position => centroidOf(points);
}

/// Groups [positions] whose markers would overlap at [zoom].
///
/// Items stay apart unless another item is within [radius] logical pixels, so
/// a lone listing keeps its true position however far out the map is zoomed.
/// Pixel distances are measured on the whole-world map, so the result depends
/// only on the zoom, not on where the user has panned.
List<ScreenCluster> clusterByScreenDistance(
  List<LatLng> positions,
  double zoom, {
  double radius = 44,
}) {
  final pixels = [
    for (final position in positions) MapCameraFocus.worldPixel(position, zoom),
  ];

  // Bucket items into radius-sized cells so each lookup checks only its
  // neighbouring cells instead of every other item.
  final cells = <(int, int), List<int>>{};
  (int, int) cellOf(int i) =>
      ((pixels[i].x / radius).floor(), (pixels[i].y / radius).floor());
  for (var i = 0; i < pixels.length; i++) {
    cells.putIfAbsent(cellOf(i), () => []).add(i);
  }

  final clustered = List.filled(positions.length, false);
  final clusters = <ScreenCluster>[];

  for (var i = 0; i < pixels.length; i++) {
    if (clustered[i]) continue;
    clustered[i] = true;
    final members = [i];

    final (cellX, cellY) = cellOf(i);
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        for (final j in cells[(cellX + dx, cellY + dy)] ?? const <int>[]) {
          if (clustered[j] || pixels[i].distanceTo(pixels[j]) > radius) {
            continue;
          }
          clustered[j] = true;
          members.add(j);
        }
      }
    }

    clusters.add(
      ScreenCluster(members, [for (final m in members) positions[m]]),
    );
  }
  return clusters;
}
