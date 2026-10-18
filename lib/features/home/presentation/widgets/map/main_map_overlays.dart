import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/presentation/providers/map_camera_provider.dart';
import 'package:genie/features/home/presentation/providers/map_properties_provider.dart';
import 'package:genie/features/home/presentation/providers/map_state_provider.dart';
import 'package:genie/features/home/presentation/providers/property_carousel_provider.dart';
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

  void _show() {
    if (_disposed) return;
    current = _listings.merge(_drawing);
    _onChanged();
  }

  Future<void> _buildListings() async {
    if (_disposed) return;

    final notifier = _ref.read(mapStateProvider.notifier);
    final mapState = _ref.read(mapStateProvider);

    if (mapState.isDrawing) {
      _ref.read(propertyCarouselProvider.notifier).clear();
    }

    _listings = await MapOverlayBuilder.buildListings(
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
