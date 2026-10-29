import 'package:flutter/painting.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tilomnov/features/home/utils/map/cluster_layout.dart';
import 'package:tilomnov/features/home/utils/map/markers/property_markers.dart';
import 'package:tilomnov/features/home/utils/map/screen_clustering.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';

/// Zoomed-out view: a green dot at each listing's real position. Dots that
/// would overlap on screen merge into a bubble showing how many it holds.
abstract final class ClusteredLayer {
  /// Adds the markers, and returns where each listing ended up so a change
  /// of zoom level can be animated. The selected listing is left out: its
  /// marker never merges.
  static Future<ClusterLayout> build({
    required List<LatLng> positions,
    required List<PropertyModel?> models,
    required double zoom,
    required Set<Marker> markers,
    required BitmapDescriptor? dotIcon,
    required BitmapDescriptor? selectedDotIcon,
    required bool Function(int index, PropertyModel? property) isHighlighted,
    required bool Function(int index) isOutlined,
    required void Function(int index, PropertyModel? property) onViewProperty,
    required void Function(List<LatLng> points) onZoomToCluster,
  }) async {
    // The listing the user is looking at never hides inside a bubble.
    final selected = [
      for (var i = 0; i < positions.length; i++)
        if (isHighlighted(i, models[i])) i,
    ];
    final others = [
      for (var i = 0; i < positions.length; i++)
        if (!selected.contains(i)) i,
    ];

    // Clusters only change at whole zoom levels, so they stay put mid-pinch.
    final clusters = clusterByScreenDistance([
      for (final i in others) positions[i],
    ], zoom.floorToDouble());
    final spotOf = <String, ClusterSpot>{};

    for (final i in selected.where((i) => !isOutlined(i))) {
      markers.add(
        _dot(
          i,
          positions[i],
          selectedDotIcon,
          isSelected: true,
          onTap: () {
            onViewProperty(i, models[i]);
          },
        ),
      );
    }

    for (final cluster in clusters) {
      if (cluster.indices.length == 1) {
        final i = others[cluster.indices.single];
        spotOf[listingKey(i, models[i])] = ClusterSpot(
          markerId: _dotId(i),
          position: positions[i],
          count: 1,
          radius: PropertyMarkers.dotRadius,
          ring: PropertyMarkers.dotRing,
        );
        markers.add(
          _dot(
            i,
            positions[i],
            dotIcon,
            isSelected: false,
            onTap: () {
              onViewProperty(i, models[i]);
            },
          ),
        );
        continue;
      }

      final count = cluster.indices.length;
      final spot = ClusterSpot(
        markerId: 'cluster_${others[cluster.indices.first]}',
        position: cluster.position,
        count: count,
        radius: PropertyMarkers.clusterDiameter(count) / 2,
        ring: PropertyMarkers.clusterRing,
        lift: PropertyMarkers.clusterLift,
      );
      for (final member in cluster.indices) {
        spotOf[listingKey(others[member], models[others[member]])] = spot;
      }

      markers.add(
        Marker(
          markerId: MarkerId(spot.markerId),
          position: cluster.position,
          icon: await PropertyMarkers.clusterBubble(count),
          anchor: const Offset(0.5, 0.5),
          consumeTapEvents: true,
          zIndexInt: 2,
          onTap: () => onZoomToCluster(cluster.points),
        ),
      );
    }

    return ClusterLayout(zoomLevel: zoom.floor(), spotOf: spotOf);
  }

  /// Names a listing the same way in every layout: by id, or by its place
  /// among the shapes drawn on this device, which have none.
  static String listingKey(int index, PropertyModel? property) =>
      property?.id ?? 'local_$index';

  static String _dotId(int index) => 'dot_$index';

  static Marker _dot(
    int index,
    LatLng position,
    BitmapDescriptor? icon, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Marker(
      markerId: MarkerId(_dotId(index)),
      position: position,
      icon:
          icon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      anchor: const Offset(0.5, 0.5),
      consumeTapEvents: true,
      zIndexInt: isSelected ? 4 : 1,
      onTap: onTap,
    );
  }
}
