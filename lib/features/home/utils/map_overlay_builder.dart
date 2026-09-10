import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/presentation/providers/map_properties_provider.dart';
import 'package:genie/features/home/presentation/providers/map_state_provider.dart';
import 'package:genie/features/home/utils/map_layer_builder.dart';
import 'package:genie/features/property/data/models/property_model.dart';

/// The icon set the overlay builder draws with. Loaded once by the map view.
class MapIcons {
  final BitmapDescriptor? pin;
  final BitmapDescriptor? greenDot;
  final BitmapDescriptor? selectedDot;
  final BitmapDescriptor? newBadge;
  final BitmapDescriptor? smallWhiteDot;

  const MapIcons({
    this.pin,
    this.greenDot,
    this.selectedDot,
    this.newBadge,
    this.smallWhiteDot,
  });
}

/// Callbacks the overlay layers invoke on user interaction.
class MapOverlayCallbacks {
  final void Function(PropertyModel property) onSelectProperty;
  final void Function(int index) onHighlightLocalPolygon;
  final void Function(List<LatLng> points) onEditProperty;
  final void Function(int index, LatLng point) onUpdatePoint;
  final void Function(int index, LatLng point) onInsertPoint;
  final void Function(int? index) onSelectVertex;
  final VoidCallback onClosePolygon;

  const MapOverlayCallbacks({
    required this.onSelectProperty,
    required this.onHighlightLocalPolygon,
    required this.onEditProperty,
    required this.onUpdatePoint,
    required this.onInsertPoint,
    required this.onSelectVertex,
    required this.onClosePolygon,
  });
}

/// The computed map layers for a single render pass.
class MapOverlays {
  final Set<Marker> markers;
  final Set<Polygon> polygons;
  final Set<Polyline> polylines;

  const MapOverlays({
    this.markers = const {},
    this.polygons = const {},
    this.polylines = const {},
  });
}

/// Turns property data plus map state into Google Maps layers.
class MapOverlayBuilder {
  static const double clusterZoomThreshold = 13.0;
  static const double detailZoomThreshold = 16.5;

  static Future<MapOverlays> build({
    required MapState mapState,
    required MapProperties mapProperties,
    required PropertyModel? selectedProperty,
    required MapIcons icons,
    required MapOverlayCallbacks callbacks,
  }) async {
    final Set<Marker> markers = {};
    final Set<Polyline> polylines = {};
    final Set<Polygon> polygons = {};

    final bool isClusteredView = mapState.currentZoom <= clusterZoomThreshold;
    final bool isDetailedView = mapState.currentZoom > detailZoomThreshold;

    // Locally drawn polygons come first so their indices stay stable; they have
    // no backend model, hence the null entries.
    final List<List<LatLng>> allProps = List.from(mapState.finalizedProperties);
    final List<bool> allPropsIsOwned =
        List.filled(mapState.finalizedProperties.length, true, growable: true);
    final List<PropertyModel?> allPropModels =
        List.filled(mapState.finalizedProperties.length, null, growable: true);

    final List<LatLng> allCentroids = [];
    final List<PropertyModel?> allCentroidModels = [];
    final List<List<LatLng>> detailedProps = [];
    final List<bool> detailedPropsIsOwned = [];
    final List<PropertyModel?> detailedPropModels = [];

    for (final property in mapProperties.properties) {
      final bool isOwned = mapProperties.isOwned(property.id);
      if (property.boundaryPoints.isNotEmpty) {
        allProps.add(property.boundaryPoints);
        allPropsIsOwned.add(isOwned);
        allPropModels.add(property);
      } else if (property.lat != null && property.lng != null) {
        allCentroids.add(LatLng(property.lat!, property.lng!));
        allCentroidModels.add(property);
      }
    }

    for (int i = 0; i < allProps.length; i++) {
      final points = allProps[i];
      if (points.length < 3) continue;

      double sumLat = 0, sumLng = 0;
      for (final point in points) {
        sumLat += point.latitude;
        sumLng += point.longitude;
      }
      allCentroids.add(LatLng(sumLat / points.length, sumLng / points.length));
      allCentroidModels.add(allPropModels[i]);
      detailedProps.add(points);
      detailedPropsIsOwned.add(allPropsIsOwned[i]);
      detailedPropModels.add(allPropModels[i]);
    }

    /// Backend properties match on id; locally drawn ones fall back to index.
    bool isHighlighted(int index, PropertyModel? property) {
      if (property != null) return selectedProperty?.id == property.id;
      return mapState.highlightedLocalPolygon == index;
    }

    if (isClusteredView) {
      MapLayerBuilder.buildClusteredView(allCentroids, markers, icons.greenDot);
    } else if (isDetailedView) {
      await MapLayerBuilder.buildDetailedView(
        detailedProps,
        detailedPropsIsOwned,
        detailedPropModels,
        polygons,
        markers,
        isHighlighted,
        mapState.currentZoom,
        (index, property) {
          if (mapState.isDrawing) return;
          if (property != null) {
            callbacks.onSelectProperty(property);
          } else {
            callbacks.onHighlightLocalPolygon(index);
          }
        },
        callbacks.onEditProperty,
      );
    } else {
      MapLayerBuilder.buildIndividualDotsView(
        allCentroids,
        allCentroidModels,
        markers,
        icons.greenDot,
        icons.selectedDot,
        icons.newBadge,
        isHighlighted,
        (index, property) {
          if (mapState.isDrawing) return;
          if (property != null) {
            callbacks.onSelectProperty(property);
          } else {
            callbacks.onHighlightLocalPolygon(index);
          }
        },
      );
    }

    if (mapState.isDrawing) {
      await MapLayerBuilder.buildDrawingLayer(
        mapState.drawnPoints,
        mapState.isEditingPolygon,
        mapState.selectedVertexIndex,
        mapState.currentZoom,
        polygons,
        markers,
        polylines,
        icons.pin,
        icons.smallWhiteDot,
        callbacks.onUpdatePoint,
        callbacks.onInsertPoint,
        callbacks.onSelectVertex,
        callbacks.onClosePolygon,
      );
    }

    return MapOverlays(
      markers: markers,
      polygons: polygons,
      polylines: polylines,
    );
  }
}
