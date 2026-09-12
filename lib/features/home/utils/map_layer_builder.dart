import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/home/utils/map_measurements.dart';
import 'package:genie/features/home/utils/map_markers.dart';

class MapLayerBuilder {
  static void buildClusteredView(
    List<LatLng> allCentroids,
    Set<Marker> newMarkers,
    BitmapDescriptor? greenDotIcon,
  ) {
    final List<LatLng> cambodiaProvinces = [
      const LatLng(11.5564, 104.9282), // Phnom Penh
      const LatLng(11.4550, 104.9489), // Kandal
      const LatLng(11.4533, 104.5209), // Kampong Speu
      const LatLng(10.9318, 104.7816), // Takeo
      const LatLng(10.5942, 104.1640), // Kampot
      const LatLng(10.6253, 103.5234), // Sihanoukville
      const LatLng(11.6155, 103.1118), // Koh Kong
      const LatLng(12.5388, 103.9192), // Pursat
      const LatLng(13.0957, 103.2022), // Battambang
      const LatLng(13.5859, 102.9737), // Banteay Meanchey
      const LatLng(14.1818, 103.5166), // Oddar Meanchey
      const LatLng(13.3611, 103.8606), // Siem Reap
      const LatLng(13.8073, 104.9806), // Preah Vihear
      const LatLng(12.7111, 104.9008), // Kampong Thom
      const LatLng(12.2500, 104.6667), // Kampong Chhnang
      const LatLng(11.4886, 105.3253), // Prey Veng
      const LatLng(11.0874, 105.7993), // Svay Rieng
      const LatLng(12.0000, 105.4500), // Kampong Cham
      const LatLng(11.8845, 105.8750), // Tboung Khmum
      const LatLng(12.4833, 106.0167), // Kratie
      const LatLng(13.5258, 105.9688), // Stung Treng
      const LatLng(13.7394, 107.0012), // Ratanakiri
      const LatLng(12.4560, 107.1881), // Mondulkiri
      const LatLng(10.4828, 104.3167), // Kep
      const LatLng(12.8489, 102.6093), // Pailin
    ];

    Set<LatLng> activeClusters = {};

    for (var centroid in allCentroids) {
      LatLng? closestProvince;
      double minDistanceSq = double.infinity;

      for (var province in cambodiaProvinces) {
        final dx = centroid.latitude - province.latitude;
        final dy = centroid.longitude - province.longitude;
        final distSq = dx * dx + dy * dy;

        if (distSq < minDistanceSq) {
          minDistanceSq = distSq;
          closestProvince = province;
        }
      }

      if (closestProvince != null) {
        activeClusters.add(closestProvince);
      }
    }

    int clusterIndex = 0;
    for (var cluster in activeClusters) {
      newMarkers.add(
        Marker(
          markerId: MarkerId('cluster_${clusterIndex++}'),
          position: cluster,
          icon: greenDotIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }
  }

  static Future<void> buildIndividualDotsView(
    List<LatLng> allCentroids,
    List<PropertyModel?> allCentroidModels,
    Set<Marker> newMarkers,
    BitmapDescriptor? greenDotIcon,
    BitmapDescriptor? selectedDotIcon,
    BitmapDescriptor? newBadgeIcon,
    bool Function(int index, PropertyModel? property) isHighlighted,
    Function(int index, PropertyModel? property) onViewProperty,
  ) async {
    final List<Future<void>> futures = [];
    
    for (int i = 0; i < allCentroids.length; i++) {
      futures.add((() async {
        final property = allCentroidModels[i];
        final bool isSelected = isHighlighted(i, property);
        
        BitmapDescriptor icon;
        if (property != null) {
          icon = await DynamicMapMarkers.createPriceMarker(
            price: property.formattedPrice,
            isNew: property.isNew,
            isSelected: isSelected,
            propertyType: property.propertyType,
            isVisited: property.isVisited,
          );
        } else {
          icon = isSelected
              ? (selectedDotIcon ?? BitmapDescriptor.defaultMarker)
              : (greenDotIcon ?? BitmapDescriptor.defaultMarker);
        }

        newMarkers.add(
          Marker(
            markerId: MarkerId('city_dot_$i'),
            position: allCentroids[i],
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            consumeTapEvents: true,
            zIndexInt: isSelected ? 4 : 1,
            onTap: () => onViewProperty(i, property),
          ),
        );
      })());
    }

    await Future.wait(futures);
  }

  static Future<void> buildDetailedView(
    List<List<LatLng>> detailedProps,
    List<bool> detailedPropsIsOwned,
    List<PropertyModel?> detailedPropModels,
    Set<Polygon> newPolygons,
    Set<Marker> newMarkers,
    bool Function(int index, PropertyModel? property) isHighlighted,
    double currentZoom,
    Function(int index, PropertyModel? property) onViewProperty,
    Function(List<LatLng> propertyPoints) onEditProperty,
  ) async {
    for (int pIndex = 0; pIndex < detailedProps.length; pIndex++) {
      final propPoints = detailedProps[pIndex];
      final bool isOwned = detailedPropsIsOwned[pIndex];
      final bool isViewed = isHighlighted(pIndex, detailedPropModels[pIndex]);

      newPolygons.add(
        Polygon(
          polygonId: PolygonId('final_polygon_$pIndex'),
          points: propPoints,
          strokeColor: const Color(0xFF4F5BD5),
          strokeWidth: isViewed ? 3 : 2,
          fillColor: const Color(0xFF4F5BD5).withValues(alpha: isViewed ? 0.25 : 0.15),
          consumeTapEvents: true,
          onTap: () => onViewProperty(pIndex, detailedPropModels[pIndex]),
        ),
      );

      final measurements = calculateMeasurements(propPoints);

      if (measurements != null) {
        final double area = measurements.area;

        if (isViewed) {
          final double areaFontSize = _calculateFontSize(area, currentZoom, isArea: true);
          final double edgeFontSize = _calculateFontSize(area, currentZoom, isArea: false);

          // Vertex numbers
          for (int i = 0; i < propPoints.length; i++) {
            final markerIcon = await DynamicMapMarkers.createNumberedMarker(i + 1);
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
              final lengthStr = '${measurements.sides[i].toStringAsFixed(0)} m';
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
            onTap: () => onEditProperty(propPoints),
          ),
        );
      }
    }
  }

  static Future<void> buildDrawingLayer(
    List<LatLng> drawnPoints,
    bool isEditingPolygon,
    int? selectedVertexIndex,
    double currentZoom,
    Set<Polygon> newPolygons,
    Set<Marker> newMarkers,
    Set<Polyline> newPolylines,
    BitmapDescriptor? pinIcon,
    BitmapDescriptor? smallWhiteDotIcon,
    Function(int index, LatLng point) onUpdatePoint,
    Function(int index, LatLng point) onInsertPoint,
    Function(int? index) onSelectVertex,
    Function() onClosePolygon,
  ) async {
    if (isEditingPolygon) {
      newPolygons.add(
        Polygon(
          polygonId: const PolygonId('edit_polygon'),
          points: drawnPoints,
          strokeColor: const Color(0xFFE5484D), // Red stroke
          strokeWidth: 2,
          fillColor: const Color(0xFFE5484D).withValues(alpha: 0.1),
        ),
      );

      final selectedVertexIconFuture = DynamicMapMarkers.createSelectedVertexMarker();
      final defaultWhiteDotFuture = DynamicMapMarkers.createSmallWhiteDotMarker();

      final measurements = calculateMeasurements(drawnPoints);
      final List<Future<BitmapDescriptor>> lengthIconFutures = [];
      Future<BitmapDescriptor>? areaIconFuture;

      if (measurements != null) {
        final double area = measurements.area;
        final bool showEdgeLengths = shouldShowDetailedView(area, currentZoom);
        final double edgeFontSize = _calculateFontSize(area, currentZoom, isArea: false);

        if (measurements.sides.isNotEmpty && showEdgeLengths) {
          for (int i = 0; i < drawnPoints.length; i++) {
            final lengthStr = '${measurements.sides[i].toStringAsFixed(0)} m';
            lengthIconFutures.add(
              DynamicMapMarkers.createTextMarker(
                lengthStr,
                fontSize: edgeFontSize,
              ),
            );
          }
        }

        areaIconFuture = DynamicMapMarkers.createTextMarker(
          formatArea(measurements.area),
          isArea: true,
          fontSize: _calculateFontSize(area, currentZoom, isArea: true),
        );
      }

      final selectedVertexIcon = await selectedVertexIconFuture;
      final defaultWhiteDot = smallWhiteDotIcon ?? await defaultWhiteDotFuture;
      final lengthIcons = await Future.wait(lengthIconFutures);
      final areaIcon = areaIconFuture != null ? await areaIconFuture : null;

      if (measurements != null) {
        final double area = measurements.area;
        final bool showEdgeLengths = shouldShowDetailedView(area, currentZoom);

        if (measurements.sides.isNotEmpty && showEdgeLengths) {
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
                icon: defaultWhiteDot,
                anchor: const Offset(0.5, 0.5),
                consumeTapEvents: true,
                draggable: true,
                onDragStart: (pos) {
                  onInsertPoint(i + 1, pos);
                },
                onDrag: (newPosition) {
                  onUpdatePoint(i + 1, newPosition);
                },
                onDragEnd: (newPosition) {
                  onUpdatePoint(i + 1, newPosition);
                },
                onTap: () {
                  onInsertPoint(i + 1, midPoint);
                },
              ),
            );

            if (i < lengthIcons.length) {
              newMarkers.add(
                Marker(
                  markerId: MarkerId('edit_length_$i'),
                  position: midPoint,
                  icon: lengthIcons[i],
                  anchor: const Offset(0.5, 0.5),
                  zIndexInt: 2,
                ),
              );
            }
          }
        }

        if (areaIcon != null) {
          double sumLat = 0, sumLng = 0;
          for (var p in drawnPoints) {
            sumLat += p.latitude;
            sumLng += p.longitude;
          }
          final LatLng centroid = LatLng(
            sumLat / drawnPoints.length,
            sumLng / drawnPoints.length,
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
      }

      for (int i = 0; i < drawnPoints.length; i++) {
        final bool isSelected = i == selectedVertexIndex;
        newMarkers.add(
          Marker(
            markerId: MarkerId('edit_point_$i'),
            position: drawnPoints[i],
            consumeTapEvents: true,
            draggable: true,
            onDragStart: (_) {
              if (!isSelected) {
                onSelectVertex(i);
              }
            },
            onDrag: (newPosition) {
              onUpdatePoint(i, newPosition);
            },
            onDragEnd: (newPosition) {
              onUpdatePoint(i, newPosition);
            },
            onTap: () {
              onSelectVertex(i);
            },
            icon: isSelected ? selectedVertexIcon : defaultWhiteDot,
            anchor: const Offset(0.5, 0.5),
            zIndexInt: isSelected ? 10 : 5,
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
                onClosePolygon();
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
            anchor: isLastPoint ? const Offset(0.5, 0.126) : const Offset(0.5, 0.5),
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
          final double edgeFontSize = _calculateFontSize(0, currentZoom, isArea: false);
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

  static bool shouldShowDetailedView(double area, double currentZoom) {
    if (area > 1000000) return currentZoom > 12.0; // 100 ha
    if (area > 100000) return currentZoom > 13.0; // 10 ha
    if (area > 10000) return currentZoom > 14.5; // 1 ha
    if (area > 5000) return currentZoom > 15.5;
    if (area > 1000) return currentZoom > 16.5;
    if (area > 500) return currentZoom > 17.5;
    if (area > 100) return currentZoom > 18.5;
    if (area > 50) return currentZoom > 19.5;
    return currentZoom > 20.0;
  }

  static double _calculateFontSize(double area, double currentZoom, {bool isArea = false}) {
    double size = isArea ? 13.5 : 11.0;

    if (currentZoom >= 19.0) {
      size *= 1.1;
    } else if (currentZoom >= 18.0) {
      size *= 1.05;
    }

    if (currentZoom <= 15.0) {
      size *= 0.8;
    } else if (currentZoom <= 13.0) {
      size *= 0.6;
    }

    if (area > 100000) {
      size *= 1.5;
    } else if (area > 10000) {
      size *= 1.3;
    }

    return size.clamp(10.0, 20.0);
  }
}
