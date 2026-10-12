import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:genie/features/home/presentation/providers/main_nav_provider.dart';
import 'package:genie/features/home/presentation/providers/map_state_provider.dart';
import 'package:genie/features/home/presentation/providers/property_carousel_provider.dart';
import 'package:genie/features/home/presentation/widgets/main_map_view.dart';
import 'package:genie/features/home/presentation/widgets/main_map_controls.dart';
import 'package:genie/features/home/presentation/widgets/main_bottom_nav.dart';
import 'package:genie/features/home/presentation/widgets/property_carousel.dart';
import 'package:genie/features/home/presentation/widgets/main_layout_pages.dart';
import 'package:genie/features/home/utils/map/map_location_service.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/widgets/detail/property_detail_sheet.dart';
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
    if (mapState.currentMapCenter == null) return;

    final controller = await _mapControllerCompleter.future;
    final notifier = ref.read(mapStateProvider.notifier);

    // Tapping near the first vertex closes the polygon instead of adding a point.
    if (mapState.drawnPoints.length >= 3) {
      final firstPointScreen = await controller.getScreenCoordinate(
        mapState.drawnPoints.first,
      );
      final crosshairScreen = await controller.getScreenCoordinate(
        mapState.currentMapCenter!,
      );

      final dx = firstPointScreen.x - crosshairScreen.x;
      final dy = firstPointScreen.y - crosshairScreen.y;

      if (dx * dx + dy * dy <= 150 * 150) {
        notifier.closePolygonForEditing();
        return;
      }
    }

    notifier.addPoint(mapState.currentMapCenter!);
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

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(mainNavProvider);
    final isHome = navState.currentIndex == 0;
    final isCardVisible = ref.watch(propertyCarouselProvider).isVisible;
    final bool overlayPage =
        navState.currentIndex == 1 ||
        navState.currentIndex == 2 ||
        navState.currentIndex == 3 ||
        navState.currentIndex == 4;

    return PopScope(
      canPop: isHome && !isCardVisible,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Dismiss the card first, then fall back to returning to the map.
        if (isCardVisible) {
          ref.read(propertyCarouselProvider.notifier).clear();
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
            IgnorePointer(
              ignoring: overlayPage,
              child: MainMapControls(
                onGoToCurrentPosition: _goToCurrentPosition,
                onAnimateToCoordinates: _animateToCoordinates,
                onAddPinToCenter: _addPinToCenter,
                onSavePropertySuccess: () {
                  ref.read(mainNavProvider.notifier).setIndex(3);
                },
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
