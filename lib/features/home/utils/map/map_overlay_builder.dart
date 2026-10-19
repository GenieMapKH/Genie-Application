import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/presentation/providers/map_properties_provider.dart';
import 'package:genie/features/home/presentation/providers/map_state_provider.dart';
import 'package:genie/features/home/utils/map/cluster_layout.dart';
import 'package:genie/features/home/utils/map/layers/clustered_layer.dart';
import 'package:genie/features/home/utils/map/layers/detailed_property_layer.dart';
import 'package:genie/features/home/utils/map/layers/drawing_callbacks.dart';
import 'package:genie/features/home/utils/map/layers/drawing_layer.dart';
import 'package:genie/features/home/utils/map/layers/layer_geometry.dart';
import 'package:genie/features/home/utils/map/layers/property_dots_layer.dart';
import 'package:genie/features/property/data/models/property_model.dart';

/// The icon set the overlay builder draws with. Loaded once by the map view.
class MapIcons {
  final BitmapDescriptor? pin;
  final BitmapDescriptor? greenDot;
  final BitmapDescriptor? selectedDot;

  /// The "New" on price tags of recent listings, in the user's language.
  final String newLabel;
  final BitmapDescriptor? smallWhiteDot;

  const MapIcons({
    this.pin,
    this.greenDot,
    this.selectedDot,
    this.newLabel = 'New',
    this.smallWhiteDot,
  });
}

/// Callbacks the overlay layers invoke on user interaction.
class MapOverlayCallbacks {
  final void Function(PropertyModel property) onSelectProperty;
  final void Function(int index) onHighlightLocalPolygon;
  final void Function(List<LatLng> points, PropertyModel? property)
  onEditProperty;
  final void Function(List<LatLng> points) onZoomToCluster;

  const MapOverlayCallbacks({
    required this.onSelectProperty,
    required this.onHighlightLocalPolygon,
    required this.onEditProperty,
    required this.onZoomToCluster,
  });
}

/// The computed map layers for a single render pass.
class MapOverlays {
  final Set<Marker> markers;
  final Set<Polygon> polygons;
  final Set<Polyline> polylines;

  /// Where the listings' dots, bubbles or price tags are.
  final ClusterLayout? clusters;

  const MapOverlays({
    this.markers = const {},
    this.polygons = const {},
    this.polylines = const {},
    this.clusters,
  });

  /// Both sets of layers drawn together.
  MapOverlays merge(MapOverlays other) => MapOverlays(
    markers: {...markers, ...other.markers},
    polygons: {...polygons, ...other.polygons},
    polylines: {...polylines, ...other.polylines},
    clusters: clusters ?? other.clusters,
  );

  /// The same layers without the markers named in [ids].
  MapOverlays withoutMarkers(Set<String> ids) => ids.isEmpty
      ? this
      : MapOverlays(
          markers: {
            for (final marker in markers)
              if (!ids.contains(marker.markerId.value)) marker,
          },
          polygons: polygons,
          polylines: polylines,
          clusters: clusters,
        );
}

/// Turns property data plus map state into Google Maps layers.
///
/// Zoomed out, listings are green dots (merged into count bubbles where they
/// would overlap); zoomed in, they are price tags. A tapped listing also shows
/// its boundary and side lengths, at any zoom.
class MapOverlayBuilder {
  /// At or below this zoom the map shows dots instead of price tags.
  static const double clusterZoomThreshold = 13.0;

  /// The listings: dots, bubbles or price tags, and the tapped one's outline.
  static Future<MapOverlays> buildListings({
    required MapState mapState,
    required double zoom,
    required MapProperties mapProperties,
    required PropertyModel? selectedProperty,
    required MapIcons icons,
    required MapOverlayCallbacks callbacks,
  }) async {
    final Set<Marker> markers = {};
    final Set<Polyline> polylines = {};
    final Set<Polygon> polygons = {};

    // One entry per listing. Locally drawn polygons come first so their index
    // matches [MapState.finalizedProperties]; they have no backend model.
    final List<LatLng> positions = [];
    final List<List<LatLng>> boundaries = [];
    final List<PropertyModel?> models = [];
    final List<bool> isOwned = [];

    for (final points in mapState.finalizedProperties) {
      positions.add(centroidOf(points));
      boundaries.add(points);
      models.add(null);
      isOwned.add(true);
    }

    for (final property in mapProperties.properties) {
      final boundary = property.boundaryPoints;
      if (boundary.length >= 3) {
        positions.add(centroidOf(boundary));
      } else if (property.lat != null && property.lng != null) {
        positions.add(LatLng(property.lat!, property.lng!));
      } else {
        continue;
      }
      boundaries.add(boundary);
      models.add(property);
      isOwned.add(mapProperties.isOwned(property.id));
    }

    /// Backend properties match on id; locally drawn ones fall back to index.
    bool isHighlighted(int index, PropertyModel? property) {
      if (property != null) return selectedProperty?.id == property.id;
      return mapState.highlightedLocalPolygon == index;
    }

    /// The tapped listing is shown by its outline alone: its card already
    /// gives the price, so a marker would only cover the area label. One
    /// without a boundary keeps its marker, or nothing would mark it.
    bool isOutlined(int index) =>
        models[index] != null &&
        boundaries[index].length >= 3 &&
        isHighlighted(index, models[index]);

    void onViewProperty(int index, PropertyModel? property) {
      if (mapState.isDrawing) return;
      if (property != null) {
        callbacks.onSelectProperty(property);
      } else {
        callbacks.onHighlightLocalPolygon(index);
      }
    }

    for (var i = 0; i < positions.length; i++) {
      if (boundaries[i].length < 3 || !isHighlighted(i, models[i])) continue;
      await DetailedPropertyLayer.build(
        index: i,
        points: boundaries[i],
        property: models[i],
        isOwned: isOwned[i],
        hasCenterMarker: !isOutlined(i),
        zoom: zoom,
        polygons: polygons,
        markers: markers,
        onViewProperty: onViewProperty,
        onEditProperty: callbacks.onEditProperty,
      );
    }

    ClusterLayout? clusters;
    if (zoom <= clusterZoomThreshold) {
      clusters = await ClusteredLayer.build(
        positions: positions,
        models: models,
        zoom: zoom,
        markers: markers,
        dotIcon: icons.greenDot,
        selectedDotIcon: icons.selectedDot,
        isHighlighted: isHighlighted,
        isOutlined: isOutlined,
        onViewProperty: onViewProperty,
        onZoomToCluster: callbacks.onZoomToCluster,
      );
    } else {
      clusters = await PropertyDotsLayer.build(
        zoom,
        icons.newLabel,
        positions,
        models,
        markers,
        icons.greenDot,
        icons.selectedDot,
        isHighlighted,
        isOutlined,
        onViewProperty,
      );
    }

    return MapOverlays(
      markers: markers,
      polygons: polygons,
      polylines: polylines,
      clusters: clusters,
    );
  }

  /// The boundary being drawn or edited. Built apart from the listings so a
  /// dragged corner redraws only this layer, many times a second.
  static Future<MapOverlays> buildDrawing({
    required MapState mapState,
    required double zoom,
    required MapIcons icons,
    required DrawingCallbacks callbacks,
  }) async {
    if (!mapState.isDrawing) return const MapOverlays();

    final Set<Marker> markers = {};
    final Set<Polyline> polylines = {};
    final Set<Polygon> polygons = {};
    await DrawingLayer.build(
      mapState: mapState,
      zoom: zoom,
      polygons: polygons,
      markers: markers,
      polylines: polylines,
      pinIcon: icons.pin,
      smallWhiteDotIcon: icons.smallWhiteDot,
      callbacks: callbacks,
    );
    return MapOverlays(
      markers: markers,
      polygons: polygons,
      polylines: polylines,
    );
  }
}
