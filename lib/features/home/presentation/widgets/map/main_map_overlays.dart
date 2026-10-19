import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/presentation/providers/map_camera_provider.dart';
import 'package:genie/features/home/presentation/providers/map_properties_provider.dart';
import 'package:genie/features/home/presentation/providers/map_state_provider.dart';
import 'package:genie/features/home/presentation/providers/property_carousel_provider.dart';
import 'package:genie/features/home/utils/map/cluster_layout.dart';
import 'package:genie/features/home/utils/map/cluster_transition.dart';
import 'package:genie/features/home/utils/map/coalesced_rebuild.dart';
import 'package:genie/features/home/utils/map/layers/drawing_callbacks.dart';
import 'package:genie/features/home/utils/map/map_overlay_builder.dart';
import 'package:genie/features/home/utils/map/markers/property_markers.dart';
import 'package:genie/features/home/utils/map/markers/vertex_markers.dart';
import 'package:genie/features/home/utils/map/svg_marker.dart';

/// Keeps the main map's two layers up to date: the listings, and the
/// boundary being drawn. Each is redrawn only when what it shows changes, so
/// a dragged corner redraws the boundary alone, many times a second.
class MainMapOverlays {
  final WidgetRef _ref;

  /// Called with each new [current], for the map to show it.
  final VoidCallback _onChanged;
  final void Function(List<LatLng> points) _onZoomToCluster;

  MapOverlays _listings = const MapOverlays();
  MapOverlays _drawing = const MapOverlays();
  MapIcons _icons = const MapIcons();
  bool _disposed = false;
  late final _rebuildListings = CoalescedRebuild(_buildListings);
  late final _rebuildDrawing = CoalescedRebuild(_buildDrawing);

  /// Both layers together, as the map draws them.
  MapOverlays current = const MapOverlays();

  /// The zoomed-out dots merging or splitting, while it plays.
  ClusterTransition? get transition => _transition;
  ClusterTransition? _transition;

  /// Whether the drops of [transition] have reached their new spots.
  bool _landed = false;

  /// Off when the user asked the system for less motion.
  bool animateClusters = true;

  MainMapOverlays({
    required WidgetRef ref,
    required VoidCallback onChanged,
    required void Function(List<LatLng> points) onZoomToCluster,
  }) : _ref = ref,
       _onChanged = onChanged,
       _onZoomToCluster = onZoomToCluster;

  /// Loads the shared icons, then draws both layers. [newLabel] is the
  /// "New" on recent listings' price tags, in the user's language.
  Future<void> loadIcons({required String newLabel}) async {
    final icons = MapIcons(
      pin: await getSvgMarker('assets/icons/pin.svg'),
      greenDot: await PropertyMarkers.greenDot(),
      selectedDot: await PropertyMarkers.greenDot(isSelected: true),
      newLabel: newLabel,
      smallWhiteDot: await VertexMarkers.smallWhiteDot(),
    );
    if (_disposed) return;
    _icons = icons;
    rebuildAll();
  }

  void rebuildAll() {
    _rebuildListings();
    _rebuildDrawing();
  }

  /// For changes only the listings show: data, the selected card, zoom.
  void rebuildListings() => _rebuildListings();

  /// Edits to the boundary being drawn redraw only the drawing layer.
  void onMapStateChanged(MapState? previous, MapState next) {
    if (previous?.isDrawing != next.isDrawing ||
        previous?.highlightedLocalPolygon != next.highlightedLocalPolygon ||
        previous?.finalizedProperties != next.finalizedProperties) {
      rebuildAll();
    } else if (previous?.drawnPoints != next.drawnPoints ||
        previous?.selectedVertexIndex != next.selectedVertexIndex ||
        previous?.draggingVertex != next.draggingVertex ||
        previous?.isEditingPolygon != next.isEditingPolygon) {
      _rebuildDrawing();
    }
  }

  /// Stops all further redraws; the map view is going away.
  void dispose() => _disposed = true;

  /// The drops have landed: the map's own markers come back underneath.
  void onTransitionLanded(ClusterTransition transition) {
    if (_transition != transition) return;
    _landed = true;
    _show();
  }

  /// The overlay is gone.
  void onTransitionDone(ClusterTransition transition) {
    if (_transition != transition || _disposed) return;
    _transition = null;
    _onChanged();
  }

  void _show() {
    if (_disposed) return;
    final moving = _transition;
    final hidden = moving != null && !_landed
        ? moving.hiddenMarkerIds
        : const <String>{};
    current = _listings.withoutMarkers(hidden).merge(_drawing);
    _onChanged();
  }

  /// Animates only a change of zoom level among dots, bubbles and price
  /// tags, on a flat north-up map (the overlay cannot follow a rotated or
  /// tilted one).
  ClusterTransition? _transitionBetween(
    ClusterLayout? from,
    ClusterLayout? to,
  ) {
    if (!animateClusters || from == null || to == null) return null;
    if (from.zoomLevel == to.zoomLevel) return null;
    if (!_ref.read(mapCameraProvider).isFlatNorthUp) return null;
    if (_ref.read(mapStateProvider).isDrawing) return null;

    return ClusterTransition.between(
      from: from,
      to: to,
      now: DateTime.now(),
      running: _landed ? null : _transition,
    );
  }

  Future<void> _buildListings() async {
    if (_disposed) return;

    final notifier = _ref.read(mapStateProvider.notifier);
    final mapState = _ref.read(mapStateProvider);

    if (mapState.isDrawing) {
      _ref.read(propertyCarouselProvider.notifier).clear();
    }

    final next = await MapOverlayBuilder.buildListings(
      mapState: mapState,
      zoom: _ref.read(mapCameraProvider).zoom,
      mapProperties: _ref.read(mapPropertiesProvider),
      selectedProperty: _ref.read(propertyCarouselProvider).selected,
      icons: _icons,
      callbacks: MapOverlayCallbacks(
        // The map view marks the listing visited when the card opens.
        onSelectProperty: (property) {
          if (_ref.read(mapStateProvider).isDrawing) return;
          _ref.read(propertyCarouselProvider.notifier).select(property);
        },
        onHighlightLocalPolygon: notifier.highlightLocalPolygon,
        onEditProperty: notifier.editProperty,
        onZoomToCluster: _onZoomToCluster,
      ),
    );
    if (_disposed) return;

    _transition = _transitionBetween(_listings.clusters, next.clusters);
    _landed = false;
    _listings = next;
    _show();
  }

  Future<void> _buildDrawing() async {
    if (_disposed) return;

    final notifier = _ref.read(mapStateProvider.notifier);
    _drawing = await MapOverlayBuilder.buildDrawing(
      mapState: _ref.read(mapStateProvider),
      zoom: _ref.read(mapCameraProvider).zoom,
      icons: _icons,
      callbacks: DrawingCallbacks(
        onUpdatePoint: notifier.updatePoint,
        onInsertPoint: notifier.insertPoint,
        onSelectVertex: notifier.selectVertex,
        onClosePolygon: notifier.closePolygonForEditing,
        onStartVertexDrag: notifier.startVertexDrag,
        onStartEdgeDrag: notifier.startEdgeDrag,
        onEndVertexDrag: notifier.endVertexDrag,
      ),
    );
    _show();
  }
}
