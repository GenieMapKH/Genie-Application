import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:genie/features/home/presentation/widgets/map_top_controls.dart';
import 'package:genie/features/home/presentation/widgets/map_floating_menu.dart';
import 'package:genie/features/home/presentation/widgets/drawing_controls_panel.dart';
import '../../../../shared/utils/app_popup.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:genie/shared/widgets/tactile_button.dart';
import 'package:genie/features/home/utils/map_measurements.dart';
import 'package:genie/features/home/utils/svg_marker.dart';
import 'package:genie/features/home/utils/map_markers.dart';
import 'package:genie/features/property/presentation/add_property_page.dart';
import 'package:genie/features/property/presentation/my_properties_page.dart';
import 'package:genie/features/property/models/property_model.dart';
import 'package:genie/features/property/data/property_providers.dart';
import 'package:genie/features/profile/presentation/user_profile_page.dart';

import 'package:genie/core/storage/auth_storage.dart';
import 'package:genie/core/storage/map_storage.dart';
import 'package:genie/features/auth/presentation/welcome_page.dart';

part 'main_layout_ui.dart';
part 'main_layout_map_logic.dart';
part 'main_layout_nav.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;
  MapSkin _currentSkin = MapSkin.defaultMap;
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  late AnimationController _animationController;
  Timer? _spinTimer;

  // Drawing Mode States
  bool _isDrawing = false;
  bool _isEditingPolygon = false;
  int? _selectedVertexIndex;
  int? _viewedPropertyIndex;

  List<LatLng> _drawnPoints = [];
  List<LatLng>? _backupPoints;
  final List<List<LatLng>> _finalizedProperties = [];
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _pinIcon;
  BitmapDescriptor? _greenDotIcon;
  BitmapDescriptor? _smallWhiteDotIcon;
  double _currentZoom = 14.4746;
  LatLng? _currentMapCenter = const LatLng(11.5564, 104.9282);
  final double _zoomThreshold = 16.5;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(11.5564, 104.9282), // Phnom Penh coordinates as default
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _loadMapIcons();
    _initLocation();
    _loadInitialMapPosition();
  }

  Future<void> _loadInitialMapPosition() async {
    final pos = await MapStorage.getLastPosition();
    if (pos != null && mounted) {
      final controller = await _mapController.future;
      controller.moveCamera(CameraUpdate.newCameraPosition(pos));
      setState(() {
        _currentZoom = pos.zoom;
        _currentMapCenter = pos.target;
      });
    }
  }

  Future<void> _initLocation() async {
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

  Future<void> _loadMapIcons() async {
    _pinIcon = await getSvgMarker('assets/icons/pin.svg');
    _greenDotIcon = await DynamicMapMarkers.createGreenDotMarker();
    _smallWhiteDotIcon = await DynamicMapMarkers.createSmallWhiteDotMarker();
    _updateMapOverlays();
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentPosition() async {
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

      final GoogleMapController controller = await _mapController.future;
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

  void _onMapTapped(LatLng position) {
    // Tapping map disabled during draw mode to enforce crosshair precision.
    if (!_isDrawing && _viewedPropertyIndex != null) {
      setState(() {
        _viewedPropertyIndex = null;
      });
      _updateMapOverlays();
    }
  }

  Future<void> _flyToAndSpin(List<LatLng> propPoints) async {
    _spinTimer?.cancel();
    final GoogleMapController controller = await _mapController.future;

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

    _spinTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
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

  bool _shouldShowEdgeLengths(double area) {
    // Edge lengths will disappear before the area bubble.
    // We require much higher zoom for smaller properties so they don't overlap.
    if (area > 1000000) return _currentZoom > 12.0; // 100 ha
    if (area > 100000) return _currentZoom > 13.0; // 10 ha
    if (area > 10000) return _currentZoom > 14.5;  // 1 ha
    if (area > 5000) return _currentZoom > 15.5;
    if (area > 1000) return _currentZoom > 16.5;
    if (area > 500) return _currentZoom > 17.5;
    if (area > 100) return _currentZoom > 18.5;
    if (area > 50) return _currentZoom > 19.5;
    return _currentZoom > 20.0;
  }

  double _calculateFontSize(double area, {bool isArea = false}) {
    double size = isArea ? 16.0 : 13.0;
    
    // Scale up for high zooms, so when zoomed in close it's larger and clearer
    if (_currentZoom >= 19.0) {
      size *= 1.2;
    } else if (_currentZoom >= 18.0) {
      size *= 1.1;
    }
    
    // Scale down for zoomed out views to reduce clutter
    if (_currentZoom <= 15.0) {
      size *= 0.8;
    } else if (_currentZoom <= 13.0) {
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
    return _buildMainLayout(context);
  }
}
