import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/l10n/l10n.dart';
import 'package:genie/features/home/presentation/providers/map_camera_provider.dart';
import 'package:genie/features/home/presentation/providers/map_properties_provider.dart';
import 'package:genie/features/home/presentation/providers/map_state_provider.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import 'package:genie/features/home/presentation/providers/main_nav_provider.dart';
import 'package:genie/features/home/presentation/providers/property_carousel_provider.dart';
import 'package:genie/features/home/utils/map/map_camera_focus.dart';
import 'package:genie/features/home/utils/map/map_overlay_builder.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/core/storage/map_storage.dart';
import 'package:genie/features/home/presentation/widgets/map/main_map_overlays.dart';
import 'package:genie/features/home/presentation/widgets/map/property_carousel.dart';

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
  late final _overlays = MainMapOverlays(
    ref: ref,
    onChanged: () {
      if (mounted) setState(() {});
    },
    onZoomToCluster: _zoomToCluster,
  );

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
    _loadInitialMapPosition();
  }

  /// The icons carry the "New" label, so they are loaded again when the
  /// language changes.
  String? _iconsLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = context.l10n;
    if (_iconsLanguage == l10n.localeName) return;
    _iconsLanguage = l10n.localeName;
    _overlays.loadIcons(newLabel: l10n.mapNewListing);
  }

  @override
  void dispose() {
    _overlays.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMapPosition() async {
    final pos = await MapStorage.getLastPosition();
    if (pos != null && mounted) {
      final controller = await widget.mapControllerCompleter.future;
      controller.moveCamera(CameraUpdate.newCameraPosition(pos));
      ref.read(mapCameraProvider.notifier).state = MapCamera(
        center: pos.target,
        zoom: pos.zoom,
      );
    }
  }

  /// Zooms in until the listings merged into a cluster bubble fit on screen,
  /// which is where they split back into separate dots or price tags.
  Future<void> _zoomToCluster(List<LatLng> points) async {
    final controller = await widget.mapControllerCompleter.future;
    var south = points.first.latitude, north = south;
    var west = points.first.longitude, east = west;
    for (final point in points) {
      south = math.min(south, point.latitude);
      north = math.max(north, point.latitude);
      west = math.min(west, point.longitude);
      east = math.max(east, point.longitude);
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        80,
      ),
    );
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

  Future<void> _handleCameraIdle() async {
    final state = ref.read(mapStateProvider);
    final camera = ref.read(mapCameraProvider);
    MapStorage.saveLastPosition(
      CameraPosition(target: camera.center, zoom: camera.zoom),
    );

    if (widget.mapControllerCompleter.isCompleted) {
      final controller = await widget.mapControllerCompleter.future;
      final visibleRegion = await controller.getVisibleRegion();
      ref.read(mapBoundsProvider.notifier).state = MapBounds(
        minLat: visibleRegion.southwest.latitude,
        maxLat: visibleRegion.northeast.latitude,
        minLng: visibleRegion.southwest.longitude,
        maxLng: visibleRegion.northeast.longitude,
      );
    }

    // Snap the crosshair onto the first point when the user pans near it, so
    // closing a polygon is easy to hit.
    if (state.isDrawing &&
        !state.isEditingPolygon &&
        state.drawnPoints.length >= 3) {
      final controller = await widget.mapControllerCompleter.future;
      final firstPointScreen = await controller.getScreenCoordinate(
        state.drawnPoints.first,
      );
      final crosshairScreen = await controller.getScreenCoordinate(
        camera.center,
      );

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

  /// Zoomed out, the dot clusters change at every whole zoom level. Zoomed
  /// in, only the measurement label sizes change, at 15, 18 and 19.
  static int _zoomBand(double zoom) {
    if (zoom <= MapOverlayBuilder.clusterZoomThreshold) return zoom.floor();
    if (zoom <= 15.0) return 100;
    if (zoom < 18.0) return 101;
    if (zoom < 19.0) return 102;
    return 103;
  }

  /// Runs on every frame of a pan or zoom, so it must stay trivial: record the
  /// camera and only touch the overlays when a zoom band is crossed.
  void _handleCameraMove(CameraPosition position) {
    final cameraNotifier = ref.read(mapCameraProvider.notifier);
    final previousZoom = cameraNotifier.state.zoom;
    cameraNotifier.state = MapCamera(
      center: position.target,
      zoom: position.zoom,
    );

    if (_zoomBand(previousZoom) != _zoomBand(position.zoom) &&
        !ref.read(mapStateProvider).isDrawing) {
      _overlays.rebuildAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch only what this widget renders. Watching the whole map state would
    // rebuild the GoogleMap (and re-diff every marker) on unrelated changes.
    final skin = ref.watch(mapStateProvider.select((s) => s.currentSkin));
    final showCrosshair = ref.watch(
      mapStateProvider.select((s) => s.isDrawing && !s.isEditingPolygon),
    );
    final navIndex = ref.watch(mainNavProvider.select((s) => s.currentIndex));

    ref.listen(mapPropertiesProvider, (_, _) => _overlays.rebuildListings());
    ref.listen(mapStateProvider, _overlays.onMapStateChanged);
    ref.listen(propertyCarouselProvider, (previous, next) {
      if (previous?.selected?.id == next.selected?.id) return;
      _overlays.rebuildListings();

      final property = next.selected;
      if (property != null) {
        _focusOnProperty(property);

        if (!property.isVisited) {
          // Optimistically mark as visited in UI when swiped to
          ref.read(visitedPropertyIdsProvider.notifier).add(property.id);
          // Send to backend
          ref.read(propertyRepositoryProvider).markAsViewed(property.id);
        }
      }
    });

    return IgnorePointer(
      ignoring: navIndex == 3 || navIndex == 4,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: -40,
            child: GoogleMap(
              mapType: skin == MapSkin.satellite
                  ? MapType.hybrid
                  : MapType.normal,
              initialCameraPosition: _initialPosition,
              onMapCreated: (GoogleMapController controller) {
                if (!widget.mapControllerCompleter.isCompleted) {
                  widget.mapControllerCompleter.complete(controller);
                }
                _overlays.rebuildAll();
              },
              onCameraMove: _handleCameraMove,
              onCameraIdle: _handleCameraIdle,
              onTap: (_) {
                final mapState = ref.read(mapStateProvider);
                if (mapState.isDrawing) return;
                ref.read(propertyCarouselProvider.notifier).clear();
                if (mapState.highlightedLocalPolygon != null) {
                  ref
                      .read(mapStateProvider.notifier)
                      .highlightLocalPolygon(null);
                }
              },
              markers: _overlays.current.markers,
              polygons: _overlays.current.polygons,
              polylines: _overlays.current.polylines,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              minMaxZoomPreference: const MinMaxZoomPreference(0, null),
              compassEnabled: false,
              mapToolbarEnabled: false,
              myLocationEnabled: true,
            ),
          ),

          // Crosshair for drawing mode
          if (showCrosshair)
            IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(
                    0,
                    20,
                  ), // Align with map center due to bottom: -40
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
