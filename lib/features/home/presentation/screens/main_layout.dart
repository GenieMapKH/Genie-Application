import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/home/presentation/widgets/map_top_controls.dart';
import '../../../../shared/utils/app_popup.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:genie/features/home/utils/svg_marker.dart';
import 'package:genie/features/home/utils/map_markers.dart';

import 'package:genie/core/storage/map_storage.dart';

import 'main_layout_ui.dart';
import 'main_layout_map_logic.dart';


class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends ConsumerState<MainLayout>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  int previousIndex = 0;
  MapSkin currentSkin = MapSkin.defaultMap;
  final Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();

  late AnimationController animationController;
  Timer? spinTimer;

  // Drawing Mode States
  bool isDrawing = false;
  bool isEditingPolygon = false;
  int? selectedVertexIndex;
  int? viewedPropertyIndex;

  List<LatLng> drawnPoints = [];
  List<LatLng>? backupPoints;
  final List<List<LatLng>> finalizedProperties = [];
  Set<Marker> markers = {};
  Set<Polygon> polygons = {};
  Set<Polyline> polylines = {};
  BitmapDescriptor? pinIcon;
  BitmapDescriptor? greenDotIcon;
  BitmapDescriptor? smallWhiteDotIcon;
  double currentZoom = 14.4746;
  LatLng? currentMapCenter = const LatLng(11.5564, 104.9282);
  final double zoomThreshold = 16.5;

  static const CameraPosition initialPosition = CameraPosition(
    target: LatLng(11.5564, 104.9282), // Phnom Penh coordinates as default
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    loadMapIcons();
    initLocation();
    loadInitialMapPosition();
  }

  Future<void> loadInitialMapPosition() async {
    final pos = await MapStorage.getLastPosition();
    if (pos != null && mounted) {
      final controller = await mapController.future;
      controller.moveCamera(CameraUpdate.newCameraPosition(pos));
      setState(() {
        currentZoom = pos.zoom;
        currentMapCenter = pos.target;
      });
    }
  }

  Future<void> initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      if (mounted) setState(() {});
    }
  }

  Future<void> loadMapIcons() async {
    pinIcon = await getSvgMarker('assets/icons/pin.svg');
    greenDotIcon = await DynamicMapMarkers.createGreenDotMarker();
    smallWhiteDotIcon = await DynamicMapMarkers.createSmallWhiteDotMarker();
    updateMapOverlays();
  }

  @override
  void dispose() {
    spinTimer?.cancel();
    animationController.dispose();
    super.dispose();
  }

  Future<void> goToCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        AppPopup.showError(
          context,
          'Location services are disabled. Please enable them.',
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          AppPopup.showError(context, 'Location permissions are denied.');
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        AppPopup.showError(
          context,
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final GoogleMapController controller = await mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppPopup.showError(context, 'Could not get location: $e');
      }
    }
  }

  void onMapTapped(LatLng position) {
    // Tapping map disabled during draw mode to enforce crosshair precision.
    if (!isDrawing && viewedPropertyIndex != null) {
      setState(() {
        viewedPropertyIndex = null;
      });
      updateMapOverlays();
    }
  }

  Future<void> flyToAndSpin(List<LatLng> propPoints) async {
    spinTimer?.cancel();
    final GoogleMapController controller = await mapController.future;

    double sumLat = 0, sumLng = 0;
    for (var p in propPoints) {
      sumLat += p.latitude;
      sumLng += p.longitude;
    }
    final center = LatLng(
      sumLat / propPoints.length,
      sumLng / propPoints.length,
    );

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: center, zoom: 19.5, tilt: 60.0),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final spinDuration = const Duration(seconds: 4);
    final startTime = DateTime.now();

    spinTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(startTime);
      if (elapsed > spinDuration) {
        timer.cancel();
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: center, zoom: 19.5, tilt: 0, bearing: 0),
          ),
        );
        return;
      }

      final progress = elapsed.inMilliseconds / spinDuration.inMilliseconds;
      final easeProgress = Curves.easeInOut.transform(progress);
      final bearing = easeProgress * 360.0;

      controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: center,
            zoom: 19.5,
            tilt: 60.0,
            bearing: bearing,
          ),
        ),
      );
    });
  }

  bool shouldShowEdgeLengths(double area) {
    // Edge lengths will disappear before the area bubble.
    // We require much higher zoom for smaller properties so they don't overlap.
    if (area > 1000000) return currentZoom > 12.0; // 100 ha
    if (area > 100000) return currentZoom > 13.0; // 10 ha
    if (area > 10000) return currentZoom > 14.5;  // 1 ha
    if (area > 5000) return currentZoom > 15.5;
    if (area > 1000) return currentZoom > 16.5;
    if (area > 500) return currentZoom > 17.5;
    if (area > 100) return currentZoom > 18.5;
    if (area > 50) return currentZoom > 19.5;
    return currentZoom > 20.0;
  }

  double calculateFontSize(double area, {bool isArea = false}) {
    double size = isArea ? 16.0 : 13.0;
    
    // Scale up for high zooms, so when zoomed in close it's larger and clearer
    if (currentZoom >= 19.0) {
      size *= 1.2;
    } else if (currentZoom >= 18.0) {
      size *= 1.1;
    }
    
    // Scale down for zoomed out views to reduce clutter
    if (currentZoom <= 15.0) {
      size *= 0.8;
    } else if (currentZoom <= 13.0) {
      size *= 0.6;
    }

    // Scale up for massive properties so they are more visible relative to the polygon
    if (area > 100000) { // 10 hectares+
      size *= 1.5;
    } else if (area > 10000) { // 1 hectare+
      size *= 1.3;
    }

    return size.clamp(10.0, 24.0);
  }

  @override
  @override
  Widget build(BuildContext context) {
    return buildMainLayout(context);
  }
}
