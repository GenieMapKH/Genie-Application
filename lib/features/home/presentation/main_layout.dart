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
    // Edge lengths will disappear before the area bubble,
    // but they show up much earlier for larger properties.
    if (area > 50000) return _currentZoom > 14.0;
    if (area > 5000) return _currentZoom > 15.0;
    if (area > 500) return _currentZoom > 16.0;
    if (area > 50) return _currentZoom > 17.0;
    return _currentZoom > 17.5;
  }

  double _calculateFontSize(double area, {bool isArea = false}) {
    double size = isArea ? 14.0 : 12.0;

    if (area <= 10000 && _currentZoom <= 16.0) {
      size *= 0.75;
    } else if (area <= 1000 && _currentZoom <= 17.5) {
      size *= 0.75;
    } else if (area <= 100 && _currentZoom <= 18.5) {
      size *= 0.75;
    } else if (area <= 50 && _currentZoom <= 19.5) {
      size *= 0.6;
    }

    return size.clamp(8.0, 16.0);
  }

  Future<void> _updateMapOverlays() async {
    final Set<Marker> newMarkers = {};
    final Set<Polyline> newPolylines = {};
    final Set<Polygon> newPolygons = {};

    final double clusterZoomThreshold = 13.0;
    final bool isClusteredView = _currentZoom <= clusterZoomThreshold;
    final bool isDetailedView = _currentZoom > _zoomThreshold;

    List<LatLng> allCentroids = [];
    List<List<LatLng>> detailedProps = [];
    List<bool> detailedPropsIsOwned =
        []; // Track ownership for each detailed property

    // 1. Gather Finalized Property Data
    final List<List<LatLng>> allProps = List.from(_finalizedProperties);
    final List<bool> allPropsIsOwned = List.filled(
      _finalizedProperties.length,
      true,
      growable: true,
    );

    final backendPropsAsync = ref.read(propertiesProvider);
    final publicPropsAsync = ref.read(publicPropertiesProvider);

    final Map<String, PropertyModel> combinedMap = {};
    final Set<String> myPropertyIds = {};

    if (publicPropsAsync.hasValue) {
      for (final p in publicPropsAsync.value!) {
        combinedMap[p.id] = p;
      }
    }

    if (backendPropsAsync.hasValue) {
      for (final p in backendPropsAsync.value!) {
        combinedMap[p.id] =
            p; // Personal properties overwrite public ones if there's overlap
        myPropertyIds.add(p.id);
      }
    }

    for (final p in combinedMap.values) {
      final bool isOwned = myPropertyIds.contains(p.id);
      if (p.boundaryPoints.isNotEmpty) {
        allProps.add(p.boundaryPoints);
        allPropsIsOwned.add(isOwned);
      } else if (p.lat != null && p.lng != null) {
        allCentroids.add(LatLng(p.lat!, p.lng!));
      }
    }

    for (int pIndex = 0; pIndex < allProps.length; pIndex++) {
      final List<LatLng> propPoints = allProps[pIndex];
      final bool isOwned = allPropsIsOwned[pIndex];

      if (propPoints.length >= 3) {
        double sumLat = 0, sumLng = 0;
        for (var p in propPoints) {
          sumLat += p.latitude;
          sumLng += p.longitude;
        }
        final LatLng centroid = LatLng(
          sumLat / propPoints.length,
          sumLng / propPoints.length,
        );
        allCentroids.add(centroid);
        detailedProps.add(propPoints);
        detailedPropsIsOwned.add(isOwned);
      }
    }

    // 2. Render Existing Properties based on Zoom Level
    if (isClusteredView) {
      // Level 1: Province Clustering (Snap to nearest province center)
      final List<LatLng> cambodiaProvinces = [
        const LatLng(11.5564, 104.9282), // Phnom Penh
        const LatLng(11.4550, 104.9489), // Kandal
        const LatLng(11.4533, 104.5209), // Kampong Speu
        const LatLng(10.9318, 104.7816), // Takeo
        const LatLng(10.5942, 104.1640), // Kampot
        const LatLng(10.6253, 103.5234), // Sihanoukville
        const LatLng(11.6155, 103.1118), // Koh Kong
        const LatLng(12.5388, 103.9192), // Pursat
        const LatLng(13.0957, 103.2022), // Battambang
        const LatLng(13.5859, 102.9737), // Banteay Meanchey
        const LatLng(14.1818, 103.5166), // Oddar Meanchey
        const LatLng(13.3611, 103.8606), // Siem Reap
        const LatLng(13.8073, 104.9806), // Preah Vihear
        const LatLng(12.7111, 104.9008), // Kampong Thom
        const LatLng(12.2500, 104.6667), // Kampong Chhnang
        const LatLng(11.4886, 105.3253), // Prey Veng
        const LatLng(11.0874, 105.7993), // Svay Rieng
        const LatLng(12.0000, 105.4500), // Kampong Cham
        const LatLng(11.8845, 105.8750), // Tboung Khmum
        const LatLng(12.4833, 106.0167), // Kratie
        const LatLng(13.5258, 105.9688), // Stung Treng
        const LatLng(13.7394, 107.0012), // Ratanakiri
        const LatLng(12.4560, 107.1881), // Mondulkiri
        const LatLng(10.4828, 104.3167), // Kep
        const LatLng(12.8489, 102.6093), // Pailin
      ];

      Set<LatLng> activeClusters = {};

      for (var centroid in allCentroids) {
        LatLng? closestProvince;
        double minDistanceSq = double.infinity;

        for (var province in cambodiaProvinces) {
          final dx = centroid.latitude - province.latitude;
          final dy = centroid.longitude - province.longitude;
          final distSq = dx * dx + dy * dy;

          if (distSq < minDistanceSq) {
            minDistanceSq = distSq;
            closestProvince = province;
          }
        }

        if (closestProvince != null) {
          activeClusters.add(closestProvince);
        }
      }

      int clusterIndex = 0;
      for (var cluster in activeClusters) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('cluster_${clusterIndex++}'),
            position: cluster,
            icon:
                _greenDotIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }
    } else if (isDetailedView) {
      // Level 3: Detailed Property Polygons + Text
      for (int pIndex = 0; pIndex < detailedProps.length; pIndex++) {
        final propPoints = detailedProps[pIndex];
        final bool isOwned = detailedPropsIsOwned[pIndex];

        newPolygons.add(
          Polygon(
            polygonId: PolygonId('final_polygon_$pIndex'),
            points: propPoints,
            strokeColor: Colors.white,
            strokeWidth: 2,
            fillColor: Colors.white.withValues(alpha: 0.15),
            consumeTapEvents: true,
            onTap: () {
              setState(() {
                _viewedPropertyIndex = pIndex;
              });
              _updateMapOverlays();
              _flyToAndSpin(propPoints);
            },
          ),
        );
        final measurements = calculateMeasurements(propPoints);

        if (measurements != null) {
          final double area = measurements.area;
          final bool isViewed = _viewedPropertyIndex == pIndex;
          
          if (isViewed) {
            final double areaFontSize = _calculateFontSize(area, isArea: true);
            final double edgeFontSize = _calculateFontSize(area, isArea: false);

            // Vertex numbers
            for (int i = 0; i < propPoints.length; i++) {
              final markerIcon = await DynamicMapMarkers.createNumberedMarker(
                i + 1,
              );
              newMarkers.add(
                Marker(
                  markerId: MarkerId('vertex_${pIndex}_$i'),
                  position: propPoints[i],
                  icon: markerIcon,
                  anchor: const Offset(0.5, 0.5),
                  zIndexInt: 3,
                ),
              );
            }

            // Edge length markers & Area
            if (measurements.sides.isNotEmpty) {
              for (int i = 0; i < propPoints.length; i++) {
                final LatLng p1 = propPoints[i];
                final LatLng p2 = propPoints[(i + 1) % propPoints.length];
                final LatLng midPoint = LatLng(
                  (p1.latitude + p2.latitude) / 2,
                  (p1.longitude + p2.longitude) / 2,
                );
                final lengthStr =
                    '${measurements.sides[i].toStringAsFixed(0)} m';
                final lengthIcon = await DynamicMapMarkers.createTextMarker(
                  lengthStr,
                  fontSize: edgeFontSize,
                );

                newMarkers.add(
                  Marker(
                    markerId: MarkerId('length_${pIndex}_$i'),
                    position: midPoint,
                    icon: lengthIcon,
                    anchor: const Offset(0.5, 0.5),
                    zIndexInt: 2,
                  ),
                );
              }

              double sumLat = 0, sumLng = 0;
              for (var p in propPoints) {
                sumLat += p.latitude;
                sumLng += p.longitude;
              }
              final LatLng centroid = LatLng(
                sumLat / propPoints.length,
                sumLng / propPoints.length,
              );

              final areaStr = formatArea(measurements.area);
              final areaIcon = await DynamicMapMarkers.createTextMarker(
                areaStr,
                isArea: true,
                fontSize: areaFontSize,
              );
              newMarkers.add(
                Marker(
                  markerId: MarkerId('area_marker_$pIndex'),
                  position: centroid,
                  icon: areaIcon,
                  anchor: const Offset(0.5, 0.5),
                  zIndexInt: 1,
                ),
              );
            }
          }
        }

        // Edit marker (only if owned)
        if (isOwned) {
          final editIcon = await DynamicMapMarkers.createEditMarker();
          newMarkers.add(
            Marker(
              markerId: MarkerId('edit_$pIndex'),
              position: propPoints[0],
              icon: editIcon,
              anchor: const Offset(1.2, 1.2),
              consumeTapEvents: true,
              onTap: () {
                setState(() {
                  _drawnPoints = List.from(propPoints);
                  _backupPoints = List.from(propPoints);
                  _finalizedProperties.remove(propPoints);
                  _isDrawing = true;
                  _isEditingPolygon = true;
                  _selectedVertexIndex = null;
                });
                _updateMapOverlays();
              },
            ),
          );
        }
      }
    } else {
      // Level 2: Individual Green Dots
      for (int i = 0; i < allCentroids.length; i++) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('city_dot_$i'),
            position: allCentroids[i],
            icon:
                _greenDotIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }
    }

    // 3. Render Drawing Layer
    if (_isDrawing) {
      if (_isEditingPolygon) {
        // Edit Mode
        newPolygons.add(
          Polygon(
            polygonId: const PolygonId('edit_polygon'),
            points: _drawnPoints,
            strokeColor: const Color(0xFFE5484D), // Red stroke
            strokeWidth: 2,
            fillColor: const Color(0xFFE5484D).withValues(alpha: 0.1),
          ),
        );

        final measurements = calculateMeasurements(_drawnPoints);
        if (measurements != null) {
          final double area = measurements.area;
          final bool showEdgeLengths = _shouldShowEdgeLengths(area);
          final double edgeFontSize = _calculateFontSize(area, isArea: false);

          if (measurements.sides.isNotEmpty) {
            if (showEdgeLengths) {
              for (int i = 0; i < _drawnPoints.length; i++) {
                final LatLng p1 = _drawnPoints[i];
                final LatLng p2 = _drawnPoints[(i + 1) % _drawnPoints.length];
                final LatLng midPoint = LatLng(
                  (p1.latitude + p2.latitude) / 2,
                  (p1.longitude + p2.longitude) / 2,
                );

                newMarkers.add(
                  Marker(
                    markerId: MarkerId('edit_midpoint_$i'),
                    position: midPoint,
                    icon:
                        _smallWhiteDotIcon ??
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                    anchor: const Offset(0.5, 0.5),
                    consumeTapEvents: true,
                    draggable: true,
                    onDragEnd: (newPosition) {
                      setState(() {
                        _drawnPoints.insert(i + 1, newPosition);
                        _selectedVertexIndex = i + 1;
                      });
                      _updateMapOverlays();
                    },
                    onTap: () {
                      setState(() {
                        _drawnPoints.insert(i + 1, midPoint);
                        _selectedVertexIndex = i + 1;
                      });
                      _updateMapOverlays();
                    },
                  ),
                );

                final lengthStr =
                    '${measurements.sides[i].toStringAsFixed(0)} m';
                final lengthIcon = await DynamicMapMarkers.createTextMarker(
                  lengthStr,
                  fontSize: edgeFontSize,
                );
                newMarkers.add(
                  Marker(
                    markerId: MarkerId('edit_length_$i'),
                    position: midPoint,
                    icon: lengthIcon,
                    anchor: const Offset(0.5, 0.5),
                    zIndexInt: 2,
                  ),
                );
              }
            }
          }

          double sumLat = 0, sumLng = 0;
          for (var p in _drawnPoints) {
            sumLat += p.latitude;
            sumLng += p.longitude;
          }
          final LatLng centroid = LatLng(
            sumLat / _drawnPoints.length,
            sumLng / _drawnPoints.length,
          );
          final areaStr = formatArea(measurements.area);
          final areaIcon = await DynamicMapMarkers.createTextMarker(
            areaStr,
            isArea: true,
            fontSize: _calculateFontSize(area, isArea: true),
          );
          newMarkers.add(
            Marker(
              markerId: const MarkerId('edit_area_marker'),
              position: centroid,
              icon: areaIcon,
              anchor: const Offset(0.5, 0.5),
              zIndexInt: 1,
            ),
          );
        }

        for (int i = 0; i < _drawnPoints.length; i++) {
          final bool isSelected = i == _selectedVertexIndex;
          newMarkers.add(
            Marker(
              markerId: MarkerId('edit_point_$i'),
              position: _drawnPoints[i],
              consumeTapEvents: true,
              draggable: isSelected,
              onDrag: (newPosition) {
                setState(() {
                  _drawnPoints[i] = newPosition;
                });
                _updateMapOverlays();
              },
              onDragEnd: (newPosition) {
                setState(() {
                  _drawnPoints[i] = newPosition;
                });
                _updateMapOverlays();
              },
              onTap: () {
                setState(() {
                  _selectedVertexIndex = i;
                });
                _updateMapOverlays();
              },
              icon: isSelected
                  ? (_pinIcon ??
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ))
                  : (_smallWhiteDotIcon ??
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        )),
              anchor: isSelected
                  ? const Offset(0.5, 0.126)
                  : const Offset(0.5, 0.5),
            ),
          );
        }
      } else {
        // Free Draw Mode
        for (int i = 0; i < _drawnPoints.length; i++) {
          final bool isLastPoint = i == _drawnPoints.length - 1;

          newMarkers.add(
            Marker(
              markerId: MarkerId('point_$i'),
              position: _drawnPoints[i],
              consumeTapEvents: true,
              onTap: () {
                if (i == 0 && _drawnPoints.length >= 3) {
                  _closePolygonForEditing();
                }
              },
              icon: isLastPoint
                  ? (_pinIcon ??
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ))
                  : (_smallWhiteDotIcon ??
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        )),
              anchor: isLastPoint
                  ? const Offset(0.5, 0.126)
                  : const Offset(0.5, 0.5),
            ),
          );
        }

        if (_drawnPoints.length >= 2) {
          newPolylines.add(
            Polyline(
              polylineId: const PolylineId('drawn_polyline'),
              points: _drawnPoints,
              color: const Color(0xFFE5484D),
              width: 2,
            ),
          );

          for (int i = 0; i < _drawnPoints.length - 1; i++) {
            final LatLng p1 = _drawnPoints[i];
            final LatLng p2 = _drawnPoints[i + 1];
            final double dist = calculateDistanceBetween(p1, p2);
            final LatLng midPoint = LatLng(
              (p1.latitude + p2.latitude) / 2,
              (p1.longitude + p2.longitude) / 2,
            );
            final lengthStr = '${dist.toStringAsFixed(0)} m';
            final double edgeFontSize = _calculateFontSize(0, isArea: false);
            final lengthIcon = await DynamicMapMarkers.createTextMarker(
              lengthStr,
              fontSize: edgeFontSize,
            );

            newMarkers.add(
              Marker(
                markerId: MarkerId('free_length_$i'),
                position: midPoint,
                icon: lengthIcon,
                anchor: const Offset(0.5, 0.5),
                zIndexInt: 2,
              ),
            );
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _polylines = newPolylines;
        _polygons = newPolygons;
      });
    }
  }

  void _closePolygonForEditing() {
    if (_drawnPoints.length < 3) return;

    setState(() {
      _isEditingPolygon = true;
    });
    _updateMapOverlays();
  }

  void _showAddPropertyForm() {
    if (_drawnPoints.length < 3) return;

    final measurements = calculateMeasurements(_drawnPoints);
    final double area = measurements?.area ?? 0.0;
    final pointsCopy = List<LatLng>.from(_drawnPoints);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddPropertyPage(boundaryPoints: pointsCopy, propertyArea: area),
      ),
    ).then((result) {
      if (result is PropertyModel) {
        setState(() {
          _isDrawing = false;
          _isEditingPolygon = false;
          _selectedVertexIndex = null;
          // _canDraw = false;
          _finalizedProperties.add(pointsCopy);
          _drawnPoints.clear();
          _backupPoints = null;
        });
        _updateMapOverlays();
        if (result.status == 'Active') {
          setState(() {
            _previousIndex = _currentIndex;
            _currentIndex = 3;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(propertiesProvider, (previous, next) {
      if (next.hasValue && next.value != previous?.value) {
        _updateMapOverlays();
      }
    });
    ref.listen(publicPropertiesProvider, (previous, next) {
      if (next.hasValue && next.value != previous?.value) {
        _updateMapOverlays();
      }
    });
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _previousIndex = _currentIndex;
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        extendBody: true, // Allow map to show through the transparent nav bar
        body: Stack(
          children: [
            IgnorePointer(
              ignoring: _currentIndex == 3 || _currentIndex == 4,
              child: Stack(
                children: [
                  // Google Map Background
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom:
                        -40, // Push the map off-screen to hide the Google logo
                    child: GoogleMap(
                      mapType: _currentSkin == MapSkin.satellite
                          ? MapType.satellite
                          : MapType.normal,
                      initialCameraPosition: _initialPosition,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController.complete(controller);
                        _updateMapOverlays();
                      },
                      onCameraMove: (CameraPosition position) {
                        _currentMapCenter = position.target;
                        final double clusterZoomThreshold = 13.0;
                        final double edgeZoomThreshold = 18.0;

                        int getZoomState(double zoom) {
                          if (zoom <= clusterZoomThreshold) return 1;
                          if (zoom <= _zoomThreshold) return 2;
                          if (zoom <= edgeZoomThreshold) return 3;
                          return 4;
                        }

                        final int prevZoomState = getZoomState(_currentZoom);
                        final int newZoomState = getZoomState(position.zoom);

                        _currentZoom = position.zoom;

                        if (prevZoomState != newZoomState && !_isDrawing) {
                          _updateMapOverlays();
                        }
                      },
                      onCameraIdle: () async {
                        if (_currentMapCenter != null) {
                          MapStorage.saveLastPosition(
                            CameraPosition(
                              target: _currentMapCenter!,
                              zoom: _currentZoom,
                            ),
                          );
                        }
                        if (_isDrawing &&
                            !_isEditingPolygon &&
                            _drawnPoints.length >= 3 &&
                            _currentMapCenter != null) {
                          final controller = await _mapController.future;
                          final firstPointScreen = await controller
                              .getScreenCoordinate(_drawnPoints.first);
                          final crosshairScreen = await controller
                              .getScreenCoordinate(_currentMapCenter!);

                          final dx = firstPointScreen.x - crosshairScreen.x;
                          final dy = firstPointScreen.y - crosshairScreen.y;
                          final distanceSquared = dx * dx + dy * dy;

                          // Magnetically snap the camera to the first pin if within ~100 screen pixels
                          // The > 5 check prevents an infinite snapping loop if we are already centered
                          if (distanceSquared <= 100 * 100 &&
                              distanceSquared > 5) {
                            controller.animateCamera(
                              CameraUpdate.newLatLng(_drawnPoints.first),
                            );
                          }
                        }
                      },
                      onTap: _onMapTapped,
                      markers: _markers,
                      polygons: _polygons,
                      polylines: _polylines,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      minMaxZoomPreference: const MinMaxZoomPreference(0, 24),
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      myLocationEnabled: true,
                    ),
                  ),
                  // Crosshair
                  if (_isDrawing && !_isEditingPolygon)
                    IgnorePointer(
                      child: Center(
                        child: Transform.translate(
                          offset: const Offset(
                            0,
                            20,
                          ), // Align with map center (due to bottom: -40)
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(
                                  0xFFE5484D,
                                ).withValues(alpha: 0.5),
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
                  // Top Search Bar and Filters
                  if (!_isDrawing)
                    MapTopControls(
                      currentSkin: _currentSkin,
                      onToggleMapType: () {
                        setState(() {
                          if (_currentSkin == MapSkin.defaultMap) {
                            _currentSkin = MapSkin.satellite;
                          } else {
                            _currentSkin = MapSkin.defaultMap;
                          }
                        });
                      },
                      onCoordinatesScanned: (result) {
                        if (mounted) {
                          setState(() {
                            _isDrawing = true;
                            _isEditingPolygon = true;
                            // _canDraw = false;
                            _drawnPoints = List.from(result);
                          });
                          _updateMapOverlays();
                          _mapController.future.then((controller) {
                            controller.animateCamera(
                              CameraUpdate.newLatLngZoom(result.first, 18),
                            );
                          });
                        }
                      },
                    ),
                  // Plus Icon and Animated Menu (Bottom Left)
                  if (!_isDrawing)
                    MapFloatingMenu(
                      onDrawPressed: () {
                        setState(() {
                          _isDrawing = true;
                          // _canDraw = false;
                        });
                        Future.delayed(const Duration(milliseconds: 300), () {
                          // if (mounted) setState(() => _canDraw = true);
                        });
                      },
                      onCoordinatesScanned: (result) {
                        if (mounted) {
                          setState(() {
                            _isDrawing = true;
                            _isEditingPolygon = true;
                            // _canDraw = false;
                            _drawnPoints = List.from(result);
                          });
                          _updateMapOverlays();
                          _mapController.future.then((controller) {
                            controller.animateCamera(
                              CameraUpdate.newLatLngZoom(result.first, 18),
                            );
                          });
                        }
                      },
                    ),
                  // Current Position Icon (Bottom Right)
                  if (!_isDrawing)
                    Positioned(
                      right: 0,
                      bottom:
                          110, // Offset for extendBody bottom navigation bar
                      child: TactileButton(
                        onPressed: _goToCurrentPosition,
                        child: SvgPicture.asset(
                          'assets/icons/current_position.svg',
                          width: 76,
                          height: 76,
                        ),
                      ),
                    ),
                  // Drawing UI Controls
                  if (_isDrawing)
                    DrawingControlsPanel(
                      isEditingPolygon: _isEditingPolygon,
                      onRevertPressed: () {
                        if (_isEditingPolygon) {
                          if (_selectedVertexIndex != null &&
                              _drawnPoints.length > 3) {
                            setState(() {
                              _drawnPoints.removeAt(_selectedVertexIndex!);
                              _selectedVertexIndex = null;
                              _updateMapOverlays();
                            });
                          }
                        } else {
                          if (_drawnPoints.isNotEmpty) {
                            setState(() {
                              _drawnPoints.removeLast();
                              _updateMapOverlays();
                            });
                          }
                        }
                      },
                      onDeletePressed: () {
                        setState(() {
                          _drawnPoints.clear();
                          if (_isEditingPolygon) {
                            _isDrawing = false;
                            _isEditingPolygon = false;
                            _selectedVertexIndex = null;
                            _backupPoints = null; // Deleted!
                            // _canDraw = false;
                          }
                          _updateMapOverlays();
                        });
                      },
                      onCancelPressed: () {
                        setState(() {
                          _isDrawing = false;
                          _isEditingPolygon = false;
                          _selectedVertexIndex = null;
                          // _canDraw = false;
                          if (_backupPoints != null) {
                            _finalizedProperties.add(_backupPoints!);
                            _backupPoints = null;
                          }
                          _drawnPoints.clear();
                          _updateMapOverlays();
                        });
                      },
                      onSavePressed: () {
                        if (_drawnPoints.length >= 3) {
                          _showAddPropertyForm();
                        } else {
                          setState(() {
                            _isDrawing = false;
                            // _canDraw = false;
                            _backupPoints = null;
                            _drawnPoints.clear();
                          });
                          _updateMapOverlays();
                        }
                      },
                      onAddPinPressed: () {
                        if (_currentMapCenter != null) {
                          _mapController.future.then((controller) async {
                            if (_drawnPoints.length >= 3) {
                              final firstPointScreen = await controller
                                  .getScreenCoordinate(_drawnPoints.first);
                              final crosshairScreen = await controller
                                  .getScreenCoordinate(_currentMapCenter!);

                              final dx = firstPointScreen.x - crosshairScreen.x;
                              final dy = firstPointScreen.y - crosshairScreen.y;
                              final distanceSquared = dx * dx + dy * dy;

                              // Auto-connect if within 150 screen pixels
                              if (distanceSquared <= 150 * 150) {
                                if (mounted) {
                                  _closePolygonForEditing();
                                }
                                return;
                              }
                            }

                            if (mounted) {
                              setState(() {
                                _drawnPoints.add(_currentMapCenter!);
                                _updateMapOverlays();
                              });
                            }
                          });
                        }
                      },
                    ),
                ],
              ),
            ),
            Container(
              color: (_currentIndex >= 3 && _previousIndex >= 3)
                  ? Colors.white
                  : Colors.transparent,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  final key = child.key as ValueKey<String>?;
                  final currentKey = _currentIndex == 3
                      ? 'my_properties'
                      : _currentIndex == 4
                      ? 'user_profile'
                      : 'empty';
                  final bool isIncoming = key?.value == currentKey;

                  Offset beginOffset;
                  if (_currentIndex > _previousIndex) {
                    beginOffset = isIncoming
                        ? const Offset(1.0, 0.0)
                        : const Offset(-1.0, 0.0);
                  } else {
                    beginOffset = isIncoming
                        ? const Offset(-1.0, 0.0)
                        : const Offset(1.0, 0.0);
                  }

                  final tween = Tween<Offset>(
                    begin: beginOffset,
                    end: Offset.zero,
                  );
                  return SlideTransition(
                    position: tween.animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: child,
                  );
                },
                child: _currentIndex == 3
                    ? MyPropertiesPage(
                        key: const ValueKey('my_properties'),
                        isEmbedded: true,
                        onBackPressed: () => setState(() {
                          _previousIndex = _currentIndex;
                          _currentIndex = 0;
                        }),
                      )
                    : _currentIndex == 4
                    ? UserProfilePage(
                        key: const ValueKey('user_profile'),
                        isEmbedded: true,
                        onBackPressed: () => setState(() {
                          _previousIndex = _currentIndex;
                          _currentIndex = 0;
                        }),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    Widget navContent = Container(
      height: 98.0,
      decoration: BoxDecoration(
        color: isIOS ? Colors.white.withValues(alpha: 0.85) : Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNavItem(
              index: 0,
              iconPath: 'assets/icons/explore.svg',
              label: 'Explore',
            ),
            _buildNavItem(
              index: 1,
              iconPath: 'assets/icons/saved.svg',
              label: 'Saved',
            ),
            _buildNavItem(
              index: 2,
              iconPath: 'assets/icons/chat.svg',
              label: 'Chat',
            ),
            _buildNavItem(
              index: 3,
              iconPath: 'assets/icons/property.svg',
              label: 'My Properties',
            ),
            _buildNavItem(
              index: 4,
              iconPath: 'assets/icons/user.svg',
              label: 'User',
            ),
          ],
        ),
      ),
    );

    if (isIOS) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: navContent,
        ),
      );
    }

    return navContent;
  }

  Widget _buildNavItem({
    required int index,
    required String iconPath,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? const Color(0xFF3E49C7)
        : const Color(0xFF6B7280);

    return TactileButton(
      onPressed: () async {
        if (index == 3 || index == 4) {
          final token = await AuthStorage.getAccessToken();
          if (token == null) {
            if (mounted) {
              _showLoginRequiredDialog(context);
            }
            return;
          }
        }
        setState(() {
          _previousIndex = _currentIndex;
          _currentIndex = index;
        });
      },
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          title: Text(
            'Account Required',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Please log in or sign up to access this feature.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF4B5563),
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B5FEF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                );
              },
              child: Text(
                'Login / Sign Up',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
