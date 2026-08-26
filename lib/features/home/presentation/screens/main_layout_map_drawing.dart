// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:genie/features/home/utils/map_measurements.dart';
import 'package:genie/features/home/utils/map_markers.dart';
import 'main_layout.dart';
import 'main_layout_map_logic.dart';

extension MainLayoutMapDrawing on MainLayoutState {
  Future<void> renderDrawingLayer(
    Set<Polygon> newPolygons,
    Set<Marker> newMarkers,
    Set<Polyline> newPolylines,
  ) async {
    if (isEditingPolygon) {
      // Edit Mode
      newPolygons.add(
        Polygon(
          polygonId: const PolygonId('edit_polygon'),
          points: drawnPoints,
          strokeColor: const Color(0xFFE5484D), // Red stroke
          strokeWidth: 2,
          fillColor: const Color(0xFFE5484D).withValues(alpha: 0.1),
        ),
      );

      final measurements = calculateMeasurements(drawnPoints);
      if (measurements != null) {
        final double area = measurements.area;
        final bool showEdgeLengths = shouldShowEdgeLengths(area);
        final double edgeFontSize = calculateFontSize(area, isArea: false);

        if (measurements.sides.isNotEmpty) {
          if (showEdgeLengths) {
            for (int i = 0; i < drawnPoints.length; i++) {
              final LatLng p1 = drawnPoints[i];
              final LatLng p2 = drawnPoints[(i + 1) % drawnPoints.length];
              final LatLng midPoint = LatLng(
                (p1.latitude + p2.latitude) / 2,
                (p1.longitude + p2.longitude) / 2,
              );

              newMarkers.add(
                Marker(
                  markerId: MarkerId('edit_midpoint_$i'),
                  position: midPoint,
                  icon:
                      smallWhiteDotIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                  anchor: const Offset(0.5, 0.5),
                  consumeTapEvents: true,
                  draggable: true,
                  onDragEnd: (newPosition) {
                    setState(() {
                      drawnPoints.insert(i + 1, newPosition);
                      selectedVertexIndex = i + 1;
                    });
                    updateMapOverlays();
                  },
                  onTap: () {
                    setState(() {
                      drawnPoints.insert(i + 1, midPoint);
                      selectedVertexIndex = i + 1;
                    });
                    updateMapOverlays();
                  },
                ),
              );

              final lengthStr =
                  '${measurements.sides[i].toStringAsFixed(0)} m';
              final lengthIcon = await DynamicMapMarkers.createTextMarker(
                lengthStr,
                fontSize: edgeFontSize,
              );
              newMarkers.add(
                Marker(
                  markerId: MarkerId('edit_length_$i'),
                  position: midPoint,
                  icon: lengthIcon,
                  anchor: const Offset(0.5, 0.5),
                  zIndexInt: 2,
                ),
              );
            }
          }
        }

        double sumLat = 0, sumLng = 0;
        for (var p in drawnPoints) {
          sumLat += p.latitude;
          sumLng += p.longitude;
        }
        final LatLng centroid = LatLng(
          sumLat / drawnPoints.length,
          sumLng / drawnPoints.length,
        );
        final areaStr = formatArea(measurements.area);
        final areaIcon = await DynamicMapMarkers.createTextMarker(
          areaStr,
          isArea: true,
          fontSize: calculateFontSize(area, isArea: true),
        );
        newMarkers.add(
          Marker(
            markerId: const MarkerId('edit_area_marker'),
            position: centroid,
            icon: areaIcon,
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 1,
          ),
        );
      }

      for (int i = 0; i < drawnPoints.length; i++) {
        final bool isSelected = i == selectedVertexIndex;
        newMarkers.add(
          Marker(
            markerId: MarkerId('edit_point_$i'),
            position: drawnPoints[i],
            consumeTapEvents: true,
            draggable: isSelected,
            onDrag: (newPosition) {
              setState(() {
                drawnPoints[i] = newPosition;
              });
              updateMapOverlays();
            },
            onDragEnd: (newPosition) {
              setState(() {
                drawnPoints[i] = newPosition;
              });
              updateMapOverlays();
            },
            onTap: () {
              setState(() {
                selectedVertexIndex = i;
              });
              updateMapOverlays();
            },
            icon: isSelected
                ? (pinIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ))
                : (smallWhiteDotIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      )),
            anchor: isSelected
                ? const Offset(0.5, 0.126)
                : const Offset(0.5, 0.5),
          ),
        );
      }
    } else {
      // Free Draw Mode
      for (int i = 0; i < drawnPoints.length; i++) {
        final bool isLastPoint = i == drawnPoints.length - 1;

        newMarkers.add(
          Marker(
            markerId: MarkerId('point_$i'),
            position: drawnPoints[i],
            consumeTapEvents: true,
            onTap: () {
              if (i == 0 && drawnPoints.length >= 3) {
                closePolygonForEditing();
              }
            },
            icon: isLastPoint
                ? (pinIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ))
                : (smallWhiteDotIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      )),
            anchor: isLastPoint
                ? const Offset(0.5, 0.126)
                : const Offset(0.5, 0.5),
          ),
        );
      }

      if (drawnPoints.length >= 2) {
        newPolylines.add(
          Polyline(
            polylineId: const PolylineId('drawn_polyline'),
            points: drawnPoints,
            color: const Color(0xFFE5484D),
            width: 2,
          ),
        );

        for (int i = 0; i < drawnPoints.length - 1; i++) {
          final LatLng p1 = drawnPoints[i];
          final LatLng p2 = drawnPoints[i + 1];
          final double dist = calculateDistanceBetween(p1, p2);
          final LatLng midPoint = LatLng(
            (p1.latitude + p2.latitude) / 2,
            (p1.longitude + p2.longitude) / 2,
          );
          final lengthStr = '${dist.toStringAsFixed(0)} m';
          final double edgeFontSize = calculateFontSize(0, isArea: false);
          final lengthIcon = await DynamicMapMarkers.createTextMarker(
            lengthStr,
            fontSize: edgeFontSize,
          );

          newMarkers.add(
            Marker(
              markerId: MarkerId('free_length_$i'),
              position: midPoint,
              icon: lengthIcon,
              anchor: const Offset(0.5, 0.5),
              zIndexInt: 2,
            ),
          );
        }
      }
    }
  }
}
