import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/presentation/providers/map_properties_provider.dart';
import 'package:genie/features/home/presentation/providers/map_state_provider.dart';
import 'package:genie/features/home/presentation/providers/main_nav_provider.dart';
import 'package:genie/features/home/presentation/providers/property_carousel_provider.dart';
import 'package:genie/features/home/utils/map_camera_focus.dart';
import 'package:genie/features/home/utils/map_markers.dart';
import 'package:genie/features/home/utils/map_overlay_builder.dart';
import 'package:genie/features/home/utils/svg_marker.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/core/storage/map_storage.dart';
import 'package:genie/features/home/presentation/widgets/property_carousel.dart';

class MainMapView extends ConsumerStatefulWidget {
  final Completer<GoogleMapController> mapControllerCompleter;

  /// Height of the map hidden behind the card carousel and bottom nav, used to
  /// keep a selected property centred in the visible strip.
  final double bottomInset;

  const MainMapView({
    super.key,
    required this.mapControllerCompleter,
    this.bottomInset = 0,
  });

  @override
  ConsumerState<MainMapView> createState() => MainMapViewState();
}

class MainMapViewState extends ConsumerState<MainMapView> {
  MapOverlays _overlays = const MapOverlays();
  MapIcons _icons = const MapIcons();

  /// The map frame extends this many logical pixels past the bottom of the
  /// screen (see the `GoogleMap`'s `bottom: -40` below), which shifts its
  /// natural camera-target position south of true screen center by half this
  /// amount. Camera framing math must account for that extra offset.
  static const double _mapFrameOverflow = 40.0;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(11.5564, 104.9282), // Phnom Penh
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _loadMapIcons();
    _loadInitialMapPosition();
  }

  Future<void> _loadMapIcons() async {
    final icons = MapIcons(
      pin: await getSvgMarker('assets/icons/pin.svg'),
      greenDot: await DynamicMapMarkers.createGreenDotMarker(),
      selectedDot: await DynamicMapMarkers.createGreenDotMarker(isSelected: true),
      newBadge: await DynamicMapMarkers.createNewBadgeMarker(),
      smallWhiteDot: await DynamicMapMarkers.createSmallWhiteDotMarker(),
    );
    if (!mounted) return;
    _icons = icons;
    _updateMapOverlays();
  }

  Future<void> _loadInitialMapPosition() async {
    final pos = await MapStorage.getLastPosition();
    if (pos != null && mounted) {
      final controller = await widget.mapControllerCompleter.future;
      controller.moveCamera(CameraUpdate.newCameraPosition(pos));
      ref.read(mapStateProvider.notifier).updateCamera(pos.target, pos.zoom);
    }
  }

  Future<void> _updateMapOverlays() async {
    if (!mounted) return;

    final notifier = ref.read(mapStateProvider.notifier);
    final overlays = await MapOverlayBuilder.build(
      mapState: ref.read(mapStateProvider),
      mapProperties: ref.read(mapPropertiesProvider),
      selectedProperty: ref.read(propertyCarouselProvider).selected,
      icons: _icons,
      callbacks: MapOverlayCallbacks(
        onSelectProperty: (property) =>
            ref.read(propertyCarouselProvider.notifier).select(property),
        onHighlightLocalPolygon: notifier.highlightLocalPolygon,
        onEditProperty: notifier.editProperty,
        onUpdatePoint: notifier.updatePoint,
        onInsertPoint: notifier.insertPoint,
        onSelectVertex: notifier.selectVertex,
        onClosePolygon: notifier.closePolygonForEditing,
      ),
    );

    if (mounted) setState(() => _overlays = overlays);
  }

  /// Frames [property] in the strip of map still visible above the card.
  Future<void> _focusOnProperty(PropertyModel property) async {
    final center = PropertyCarouselNotifier.centerOf(property);
    if (center == null) return;

    final controller = await widget.mapControllerCompleter.future;
    if (!mounted) return;

    final size = MediaQuery.sizeOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    // MapTopControls is roughly 140px tall (search bar + filters + padding)
    final topInset = topPadding + 140.0;
    // Add extra bottom offset to move the property "to the bottom a little bit" as requested
    final extraBottomOffset = 40.0;
    
    // When a property is clicked, the parent widget may not have rebuilt yet with the updated bottomInset.
    // Since _focusOnProperty is only called for selected properties, we know the carousel will be visible,
    // so we proactively use PropertyCarousel.mapInset for the target calculations.
    final targetBottomInset = PropertyCarousel.mapInset;
    
    final visibleHeight = size.height - targetBottomInset - topInset;

    final double zoom = property.boundaryPoints.length >= 3
        ? MapCameraFocus.zoomToFit(
            property.boundaryPoints,
            size.width,
            visibleHeight,
          )
        : MapCameraFocus.pinZoom;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: MapCameraFocus.offsetForBottomInset(
            center,
            zoom,
            targetBottomInset + _mapFrameOverflow + extraBottomOffset,
            topInset: topInset,
          ),
          zoom: zoom,
        ),
      ),
    );
  }

  void _handleMapStateChange(MapState? previous, MapState next) {
    if (previous?.drawnPoints != next.drawnPoints ||
        previous?.isDrawing != next.isDrawing ||
        previous?.highlightedLocalPolygon != next.highlightedLocalPolygon ||
        previous?.selectedVertexIndex != next.selectedVertexIndex ||
        previous?.isEditingPolygon != next.isEditingPolygon) {
      _updateMapOverlays();
    }
  }

  Future<void> _handleCameraIdle() async {
    final state = ref.read(mapStateProvider);
    if (state.currentMapCenter != null) {
      MapStorage.saveLastPosition(
        CameraPosition(target: state.currentMapCenter!, zoom: state.currentZoom),
      );
    }

    // Snap the crosshair onto the first point when the user pans near it, so
    // closing a polygon is easy to hit.
    if (state.isDrawing &&
        !state.isEditingPolygon &&
        state.drawnPoints.length >= 3 &&
        state.currentMapCenter != null) {
      final controller = await widget.mapControllerCompleter.future;
      final firstPointScreen =
          await controller.getScreenCoordinate(state.drawnPoints.first);
      final crosshairScreen =
          await controller.getScreenCoordinate(state.currentMapCenter!);

      final dx = firstPointScreen.x - crosshairScreen.x;
      final dy = firstPointScreen.y - crosshairScreen.y;
      final distanceSquared = dx * dx + dy * dy;

      if (distanceSquared <= 100 * 100 && distanceSquared > 5) {
        controller.animateCamera(
          CameraUpdate.newLatLng(state.drawnPoints.first),
        );
      }
    }
  }

  void _handleCameraMove(CameraPosition position) {
    final mapState = ref.read(mapStateProvider);

    int zoomBand(double zoom) {
      if (zoom <= MapOverlayBuilder.clusterZoomThreshold) return 1;
      if (zoom <= MapOverlayBuilder.detailZoomThreshold) return 2;
      if (zoom <= 18.0) return 3;
      return 4;
    }

    final bool bandChanged =
        zoomBand(mapState.currentZoom) != zoomBand(position.zoom);

    ref.read(mapStateProvider.notifier).updateCamera(position.target, position.zoom);

    if (bandChanged && !mapState.isDrawing) _updateMapOverlays();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapStateProvider);
    final navState = ref.watch(mainNavProvider);

    ref.listen(mapPropertiesProvider, (_, _) => _updateMapOverlays());
    ref.listen(mapStateProvider, _handleMapStateChange);
    ref.listen(propertyCarouselProvider, (previous, next) {
      if (previous?.selected?.id == next.selected?.id) return;
      _updateMapOverlays();
      if (next.selected != null) _focusOnProperty(next.selected!);
    });

    return IgnorePointer(
      ignoring: navState.currentIndex == 3 || navState.currentIndex == 4,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: -40,
            child: GoogleMap(
              mapType: mapState.currentSkin == MapSkin.satellite
                  ? MapType.hybrid
                  : MapType.normal,
              initialCameraPosition: _initialPosition,
              onMapCreated: (GoogleMapController controller) {
                if (!widget.mapControllerCompleter.isCompleted) {
                  widget.mapControllerCompleter.complete(controller);
                }
                _updateMapOverlays();
              },
              onCameraMove: _handleCameraMove,
              onCameraIdle: _handleCameraIdle,
              onTap: (_) {
                if (mapState.isDrawing) return;
                ref.read(propertyCarouselProvider.notifier).clear();
                if (mapState.highlightedLocalPolygon != null) {
                  ref.read(mapStateProvider.notifier).highlightLocalPolygon(null);
                }
              },
              markers: _overlays.markers,
              polygons: _overlays.polygons,
              polylines: _overlays.polylines,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              minMaxZoomPreference: const MinMaxZoomPreference(0, null),
              compassEnabled: false,
              mapToolbarEnabled: false,
              myLocationEnabled: true,
            ),
          ),

          // Crosshair for drawing mode
          if (mapState.isDrawing && !mapState.isEditingPolygon)
            IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, 20), // Align with map center due to bottom: -40
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE5484D).withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        size: 28,
                        color: Color(0xFFE5484D),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
