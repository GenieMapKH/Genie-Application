import 'package:flutter/painting.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/utils/map/markers/property_markers.dart';
import 'package:genie/features/home/utils/map/screen_clustering.dart';
import 'package:genie/features/property/data/models/property_model.dart';

/// Zoomed-out view: a green dot at each listing's real position. Dots that
/// would overlap on screen merge into a bubble showing how many it holds.
abstract final class ClusteredLayer {
  static Future<void> build({
    required List<LatLng> positions,
    required List<PropertyModel?> models,
    required double zoom,
    required Set<Marker> markers,
    required BitmapDescriptor? dotIcon,
    required BitmapDescriptor? selectedDotIcon,
    required bool Function(int index, PropertyModel? property) isHighlighted,
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

    for (final i in selected) {
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

      markers.add(
        Marker(
          markerId: MarkerId('cluster_${others[cluster.indices.first]}'),
          position: cluster.position,
          icon: await PropertyMarkers.clusterBubble(cluster.indices.length),
          anchor: const Offset(0.5, 0.5),
          consumeTapEvents: true,
          zIndexInt: 2,
          onTap: () => onZoomToCluster(cluster.points),
        ),
      );
    }
  }

  static Marker _dot(
    int index,
    LatLng position,
    BitmapDescriptor? icon, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Marker(
      markerId: MarkerId('dot_$index'),
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
