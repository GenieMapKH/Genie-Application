import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:genie/features/home/presentation/providers/main_nav_provider.dart';
import 'package:genie/features/home/presentation/providers/map_camera_provider.dart';
import 'package:genie/features/home/presentation/providers/map_state_provider.dart';
import 'package:genie/features/home/presentation/providers/property_carousel_provider.dart';
import 'package:genie/features/home/presentation/widgets/map/main_map_view.dart';
import 'package:genie/features/home/presentation/widgets/map/main_map_controls.dart';
import 'package:genie/features/home/presentation/widgets/layout/main_bottom_nav.dart';
import 'package:genie/features/home/presentation/widgets/map/property_carousel.dart';
import 'package:genie/features/home/presentation/widgets/layout/main_layout_pages.dart';
import 'package:genie/features/home/presentation/widgets/search/home_search_panel.dart';
import 'package:genie/features/home/utils/map/map_camera_focus.dart';
import 'package:genie/features/home/utils/map/map_overlay_builder.dart';
import 'package:genie/features/home/utils/map/map_location_service.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/widgets/detail/property_detail_sheet.dart';
import 'package:genie/features/search/presentation/search_layout.dart';
import 'package:genie/features/search/presentation/view_models/search_area_controller.dart';
import 'package:genie/features/security/presentation/widgets/new_sign_in_alert.dart';
import 'package:genie/shared/utils/app_popup.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  final Completer<GoogleMapController> _mapControllerCompleter =
      Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();
    MapLocationService.warmUp();
    _checkAuthNavState();
  }

  Future<void> _checkAuthNavState() async {
    final token = await AuthStorage.getAccessToken();
    if ((token == null || token.isEmpty) && mounted) {
      final currentIdx = ref.read(mainNavProvider).currentIndex;
      if (currentIdx == 1 ||
          currentIdx == 2 ||
          currentIdx == 3 ||
          currentIdx == 4) {
        ref.read(mainNavProvider.notifier).resetToHome();
      }
    }
  }

  Future<void> _goToCurrentPosition() async {
    final result = await MapLocationService.currentPosition();
    if (!mounted) return;

    if (!result.isSuccess) {
      AppPopup.showError(context, result.error!);
      return;
    }

    await MapLocationService.animateTo(
      _mapControllerCompleter,
      LatLng(result.position!.latitude, result.position!.longitude),
    );
  }

  Future<void> _animateToCoordinates(List<LatLng> coords) async {
    if (coords.isEmpty) return;
    await MapLocationService.animateTo(
      _mapControllerCompleter,
      coords.first,
      zoom: 21.5,
    );
  }

  Future<void> _addPinToCenter() async {
    final mapState = ref.read(mapStateProvider);
    final center = ref.read(mapCameraProvider).center;

    final controller = await _mapControllerCompleter.future;
    final notifier = ref.read(mapStateProvider.notifier);

    // Tapping near the first vertex closes the polygon instead of adding a point.
    if (mapState.drawnPoints.length >= 3) {
      final firstPointScreen = await controller.getScreenCoordinate(
        mapState.drawnPoints.first,
      );
      final crosshairScreen = await controller.getScreenCoordinate(center);

      final dx = firstPointScreen.x - crosshairScreen.x;
      final dy = firstPointScreen.y - crosshairScreen.y;

      if (dx * dx + dy * dy <= 150 * 150) {
        notifier.closePolygonForEditing();
        return;
      }
    }

    notifier.addPoint(center);
  }

  /// Opens the detail sheet, keeping the map's selection in sync so the sheet
  /// and the card underneath always describe the same property.
  void _openPropertyDetail(PropertyModel property) {
    ref.read(propertyCarouselProvider.notifier).select(property);
    Navigator.of(context).push(
      PropertyDetailSheet.route(
        property,
        onOpenProperty: (next) {
          Navigator.of(context).pop();
          _openPropertyDetail(next);
        },
      ),
    );
  }

  /// The map extends this far below the screen (see `MainMapView`).
  static const double _mapFrameOverflow = 40.0;

  /// A new place or person was picked: make room for its panel, and frame its
  /// area on the map once it is known.
  void _onSearchAreaChanged(SearchAreaState? previous, SearchAreaState? next) {
    if (next == null) return;
    final isNewTarget = previous?.target != next.target;
    if (isNewTarget) ref.read(propertyCarouselProvider.notifier).clear();

    final bounds = next.area.valueOrNull?.framing;
    final justLoaded = previous?.area is! AsyncData || isNewTarget;
    if (bounds != null && justLoaded) _frameOnMap(bounds);
  }

  Future<void> _frameOnMap(LatLngBounds bounds) async {
    final size = MediaQuery.sizeOf(context);
    final covered =
        HomeSearchPanel.coveredInsets(context) +
        const EdgeInsets.only(bottom: _mapFrameOverflow);
    final controller = await _mapControllerCompleter.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        MapCameraFocus.frame(
          bounds,
          Size(size.width, size.height + _mapFrameOverflow),
          covered,
          // Below this the map shows dots instead of price tags.
          minZoom: MapOverlayBuilder.clusterZoomThreshold + 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(mainNavProvider);
    final isHome = navState.currentIndex == 0;
    final isCardVisible = ref.watch(propertyCarouselProvider).isVisible;
    final hasSearch = ref.watch(
      searchAreaControllerProvider.select((state) => state != null),
    );
    final isDrawing = ref.watch(
      mapStateProvider.select((state) => state.isDrawing),
    );
    final showSearchPanel = hasSearch && isHome && !isCardVisible && !isDrawing;
    final searchSheetHeight =
        showSearchPanel &&
            !SearchLayout.isWide(MediaQuery.sizeOf(context).width)
        ? HomeSearchPanel.coveredInsets(context).bottom
        : 0.0;
    ref.listen<SearchAreaState?>(
      searchAreaControllerProvider,
      _onSearchAreaChanged,
    );
    final bool overlayPage =
        navState.currentIndex == 1 ||
        navState.currentIndex == 2 ||
        navState.currentIndex == 3 ||
        navState.currentIndex == 4;

    return PopScope(
      canPop: isHome && !isCardVisible && !hasSearch,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Dismiss the card first, then the search, then return to the map.
        if (isCardVisible) {
          ref.read(propertyCarouselProvider.notifier).clear();
        } else if (isHome && hasSearch) {
          ref.read(searchAreaControllerProvider.notifier).clear();
        } else if (!isHome) {
          ref.read(mainNavProvider.notifier).resetToHome();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            MainMapView(
              mapControllerCompleter: _mapControllerCompleter,
              bottomInset: isCardVisible ? PropertyCarousel.mapInset : 0,
            ),
            HomeSearchPanel(
              aboveControls: false,
              visible: showSearchPanel,
              onOpenProperty: _openPropertyDetail,
            ),
            IgnorePointer(
              ignoring: overlayPage,
              child: MainMapControls(
                onGoToCurrentPosition: _goToCurrentPosition,
                onAnimateToCoordinates: _animateToCoordinates,
                onAddPinToCenter: _addPinToCenter,
                onSavePropertySuccess: () {
                  ref.read(mainNavProvider.notifier).setIndex(3);
                },
                onOpenProperty: _openPropertyDetail,
                searchSheetHeight: searchSheetHeight,
              ),
            ),

            // Property card carousel, sitting directly on the bottom nav.
            Positioned(
              left: 0,
              right: 0,
              bottom: PropertyCarousel.bottomNavHeight - 8,
              child: IgnorePointer(
                ignoring: !isHome,
                child: PropertyCarousel(onOpenDetail: _openPropertyDetail),
              ),
            ),

            HomeSearchPanel(
              aboveControls: true,
              visible: showSearchPanel,
              onOpenProperty: _openPropertyDetail,
            ),

            MainLayoutPages(navState: navState),

            // Draws nothing: speaks up when another device signs in.
            const NewSignInAlert(),
          ],
        ),
        bottomNavigationBar: const MainBottomNav(),
      ),
    );
  }
}
