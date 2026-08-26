// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:genie/features/home/utils/map_measurements.dart';
import 'package:genie/features/home/utils/map_markers.dart';
import 'main_layout.dart';
import 'main_layout_map_logic.dart';

extension MainLayoutMapDetails on MainLayoutState {
  Future<void> renderDetailedView(
    List<List<LatLng>> detailedProps,
    List<bool> detailedPropsIsOwned,
    Set<Polygon> newPolygons,
    Set<Marker> newMarkers,
  ) async {
    for (int pIndex = 0; pIndex < detailedProps.length; pIndex++) {
      final propPoints = detailedProps[pIndex];
      final bool isOwned = detailedPropsIsOwned[pIndex];

      newPolygons.add(
        Polygon(
          polygonId: PolygonId('final_polygon_$pIndex'),
          points: propPoints,
          strokeColor: const Color(0xFF4F5BD5),
          strokeWidth: 2,
          fillColor: const Color(0xFF4F5BD5).withValues(alpha: 0.15),
          consumeTapEvents: true,
          onTap: () {
            setState(() {
              viewedPropertyIndex = pIndex;
            });
            updateMapOverlays();
            flyToAndSpin(propPoints);
          },
        ),
      );
      final measurements = calculateMeasurements(propPoints);

      if (measurements != null) {
        final double area = measurements.area;
        final bool isViewed = viewedPropertyIndex == pIndex;

        if (isViewed) {
          final double areaFontSize = calculateFontSize(area, isArea: true);
          final double edgeFontSize = calculateFontSize(area, isArea: false);

          // Vertex numbers
          for (int i = 0; i < propPoints.length; i++) {
            final markerIcon = await DynamicMapMarkers.createNumberedMarker(
              i + 1,
            );
            newMarkers.add(
              Marker(
                markerId: MarkerId('vertex_${pIndex}_$i'),
                position: propPoints[i],
                icon: markerIcon,
                anchor: const Offset(0.5, 0.5),
                zIndexInt: 3,
              ),
            );
          }

          // Edge length markers & Area
          if (measurements.sides.isNotEmpty) {
            for (int i = 0; i < propPoints.length; i++) {
              final LatLng p1 = propPoints[i];
              final LatLng p2 = propPoints[(i + 1) % propPoints.length];
              final LatLng midPoint = LatLng(
                (p1.latitude + p2.latitude) / 2,
                (p1.longitude + p2.longitude) / 2,
              );
              final lengthStr =
                  '${measurements.sides[i].toStringAsFixed(0)} m';
              final lengthIcon = await DynamicMapMarkers.createTextMarker(
                lengthStr,
                fontSize: edgeFontSize,
              );

              newMarkers.add(
                Marker(
                  markerId: MarkerId('length_${pIndex}_$i'),
                  position: midPoint,
                  icon: lengthIcon,
                  anchor: const Offset(0.5, 0.5),
                  zIndexInt: 2,
                ),
              );
            }

            double sumLat = 0, sumLng = 0;
            for (var p in propPoints) {
              sumLat += p.latitude;
              sumLng += p.longitude;
            }
            final LatLng centroid = LatLng(
              sumLat / propPoints.length,
              sumLng / propPoints.length,
            );

            final areaStr = formatArea(measurements.area);
            final areaIcon = await DynamicMapMarkers.createTextMarker(
              areaStr,
              isArea: true,
              fontSize: areaFontSize,
            );
            newMarkers.add(
              Marker(
                markerId: MarkerId('area_marker_$pIndex'),
                position: centroid,
                icon: areaIcon,
                anchor: const Offset(0.5, 0.5),
                zIndexInt: 1,
              ),
            );
          }
        }
      }

      // Edit marker (only if owned)
      if (isOwned) {
        final editIcon = await DynamicMapMarkers.createEditMarker();
        newMarkers.add(
          Marker(
            markerId: MarkerId('edit_$pIndex'),
            position: propPoints[0],
            icon: editIcon,
            anchor: const Offset(1.2, 1.2),
            consumeTapEvents: true,
            onTap: () {
              setState(() {
                drawnPoints = List.from(propPoints);
                backupPoints = List.from(propPoints);
                finalizedProperties.remove(propPoints);
                isDrawing = true;
                isEditingPolygon = true;
                selectedVertexIndex = null;
              });
              updateMapOverlays();
            },
          ),
        );
      }
    }
  }
}
