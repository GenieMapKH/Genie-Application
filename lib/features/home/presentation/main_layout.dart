import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:genie/features/home/presentation/widgets/utm_locate_bottom_sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:genie/shared/widgets/tactile_button.dart';
import 'package:genie/features/home/utils/map_measurements.dart';
import 'package:genie/features/home/utils/svg_marker.dart';
import 'package:genie/features/home/utils/map_markers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/ocr_parser.dart';

enum MapSkin { defaultMap, satellite }

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  MapSkin _currentSkin = MapSkin.defaultMap;
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  bool _isMenuOpen = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  Timer? _spinTimer;

  // Drawing Mode States
  bool _isDrawing = false;
  bool _canDraw = false; // Used to prevent taps immediately after entering drawing mode
  bool _isEditingPolygon = false;
  int? _selectedVertexIndex;
  
  List<LatLng> _drawnPoints = [];
  List<LatLng>? _backupPoints;
  List<List<LatLng>> _finalizedProperties = [];
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _pinIcon;
  BitmapDescriptor? _greenDotIcon;
  BitmapDescriptor? _detailedPropertyIcon;
  BitmapDescriptor? _smallWhiteDotIcon;
  double _currentZoom = 14.4746;
  LatLng? _currentMapCenter = const LatLng(11.5564, 104.9282);
  final double _zoomThreshold = 16.5;

  final List<LatLng> _dummyProperties = [
    const LatLng(11.5564, 104.9282),
    const LatLng(11.5580, 104.9290),
    const LatLng(11.5550, 104.9270),
    const LatLng(11.5575, 104.9265),
  ];

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
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _loadMapIcons();
  }

  Future<void> _loadMapIcons() async {
    _pinIcon = await getSvgMarker('assets/icons/pin.svg');
    _greenDotIcon = await DynamicMapMarkers.createGreenDotMarker();
    _detailedPropertyIcon = await DynamicMapMarkers.createTextMarker(
      '\$120,000',
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location services are disabled. Please enable them.',
            ),
          ),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied, we cannot request permissions.',
            ),
          ),
        );
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
      }
    }
  }

  Widget _buildAnimatedMenuItem({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TactileButton(
                onPressed: () {
                  // Close menu on tap and trigger action
                  setState(() {
                    _isMenuOpen = false;
                    _animationController.reverse();
                  });
                  onTap();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      iconPath,
                      width: 22,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF4B5563),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton(
    String iconPath, {
    required VoidCallback onPressed,
  }) {
    return TactileButton(
      onPressed: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: SvgPicture.asset(iconPath, width: 34, height: 34)),
      ),
    );
  }

  void _onMapTapped(LatLng position) {
    // Tapping map disabled during draw mode to enforce crosshair precision.
  }
  
  Future<void> _flyToAndSpin(List<LatLng> propPoints) async {
    _spinTimer?.cancel();
    final GoogleMapController controller = await _mapController.future;

    double sumLat = 0, sumLng = 0;
    for (var p in propPoints) {
      sumLat += p.latitude;
      sumLng += p.longitude;
    }
    final center = LatLng(sumLat / propPoints.length, sumLng / propPoints.length);

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: center,
          zoom: 19.5,
          tilt: 60.0,
        ),
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
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: 19.5, tilt: 0, bearing: 0)
        ));
        return;
      }
      
      final progress = elapsed.inMilliseconds / spinDuration.inMilliseconds;
      final easeProgress = Curves.easeInOut.transform(progress);
      final bearing = easeProgress * 360.0;
      
      controller.moveCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: center,
          zoom: 19.5,
          tilt: 60.0,
          bearing: bearing,
        ),
      ));
    });
  }

  Future<void> _animateToPolygon(List<LatLng> points) async {
    if (points.isEmpty) return;
    
    final GoogleMapController controller = await _mapController.future;
    
    if (points.length == 1) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(points.first, 18.0));
      return;
    }
    
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0, // padding
      ),
    );
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
    List<LatLng> dummyProps = _dummyProperties;

    // 1. Gather Finalized Property Data
    for (int pIndex = 0; pIndex < _finalizedProperties.length; pIndex++) {
      final List<LatLng> propPoints = _finalizedProperties[pIndex];
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
      }
    }

    // Gather Dummy Property Data
    allCentroids.addAll(dummyProps);

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
            icon: _greenDotIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }
    } else if (isDetailedView) {
      // Level 3: Detailed Property Polygons + Text
      for (int pIndex = 0; pIndex < detailedProps.length; pIndex++) {
        final propPoints = detailedProps[pIndex];
        
        newPolygons.add(
          Polygon(
            polygonId: PolygonId('final_polygon_$pIndex'),
            points: propPoints,
            strokeColor: Colors.white,
            strokeWidth: 2,
            fillColor: Colors.white.withValues(alpha: 0.01),
            consumeTapEvents: true,
            onTap: () => _flyToAndSpin(propPoints),
          ),
        );
        final measurements = calculateMeasurements(propPoints);

        final bool showEdgeLengths = _currentZoom > 18.0;

        // Vertex numbers
        if (showEdgeLengths) {
          for (int i = 0; i < propPoints.length; i++) {
            final markerIcon = await DynamicMapMarkers.createNumberedMarker(i + 1);
            newMarkers.add(
              Marker(
                markerId: MarkerId('vertex_${pIndex}_$i'),
                position: propPoints[i],
                icon: markerIcon,
                anchor: const Offset(0.5, 0.5),
              ),
            );
          }
        }

        // Edge length markers & Area
        if (measurements != null && measurements.sides.isNotEmpty) {
          if (showEdgeLengths) {
            for (int i = 0; i < propPoints.length; i++) {
              final LatLng p1 = propPoints[i];
              final LatLng p2 = propPoints[(i + 1) % propPoints.length];
              final LatLng midPoint = LatLng(
                (p1.latitude + p2.latitude) / 2,
                (p1.longitude + p2.longitude) / 2,
              );
              final lengthStr = '${measurements.sides[i].toStringAsFixed(0)} m';
              final lengthIcon = await DynamicMapMarkers.createTextMarker(lengthStr);

              newMarkers.add(
                Marker(
                  markerId: MarkerId('length_${pIndex}_$i'),
                  position: midPoint,
                  icon: lengthIcon,
                  anchor: const Offset(0.5, 0.5),
                ),
              );
            }
          }

          double sumLat = 0, sumLng = 0;
          for (var p in propPoints) { sumLat += p.latitude; sumLng += p.longitude; }
          final LatLng centroid = LatLng(sumLat / propPoints.length, sumLng / propPoints.length);
          
          final areaStr = '${measurements.area.toStringAsFixed(0)} m²';
          final areaIcon = await DynamicMapMarkers.createTextMarker(areaStr, isArea: true);
          newMarkers.add(
            Marker(
              markerId: MarkerId('area_marker_$pIndex'),
              position: centroid,
              icon: areaIcon,
              anchor: const Offset(0.5, 0.5),
            ),
          );
        }

        // Edit marker
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
                _canDraw = false;
              });
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) setState(() => _canDraw = true);
              });
              _updateMapOverlays();
            },
          ),
        );
      }

      // Detailed view for dummy properties (Price Tags)
      for (int i = 0; i < dummyProps.length; i++) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('dummy_detail_$i'),
            position: dummyProps[i],
            icon: _detailedPropertyIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }
    } else {
      // Level 2: Individual Green Dots
      for (int i = 0; i < allCentroids.length; i++) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('city_dot_$i'),
            position: allCentroids[i],
            icon: _greenDotIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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
        if (measurements != null && measurements.sides.isNotEmpty) {
          final bool showEdgeLengths = _currentZoom > 18.0;
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
                  icon: _smallWhiteDotIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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
            }
          }

          double sumLat = 0, sumLng = 0;
          for (var p in _drawnPoints) {
            sumLat += p.latitude;
            sumLng += p.longitude;
          }
          final LatLng centroid = LatLng(sumLat / _drawnPoints.length, sumLng / _drawnPoints.length);
          final areaStr = '${measurements.area.toStringAsFixed(0)} m²';
          final areaIcon = await DynamicMapMarkers.createTextMarker(areaStr, isArea: true);
          newMarkers.add(
            Marker(
              markerId: const MarkerId('edit_area_marker'),
              position: centroid,
              icon: areaIcon,
              anchor: const Offset(0.5, 0.5),
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
                  ? (_pinIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))
                  : (_smallWhiteDotIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
              anchor: isSelected ? const Offset(0.5, 0.126) : const Offset(0.5, 0.5),
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
                  setState(() {
                    _isDrawing = false;
                    _canDraw = false;
                    _finalizedProperties.add(List.from(_drawnPoints));
                    _drawnPoints.clear();
                  });
                  _updateMapOverlays();
                }
              },
              icon: isLastPoint
                  ? (_pinIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))
                  : (_smallWhiteDotIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
              anchor: isLastPoint ? const Offset(0.5, 0.126) : const Offset(0.5, 0.5),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: -40, // Push the map off-screen to hide the Google logo
            child: GoogleMap(
              mapType: _currentSkin == MapSkin.satellite
                  ? MapType.satellite
                  : MapType.normal,
              initialCameraPosition: _initialPosition,
              onMapCreated: (GoogleMapController controller) {
                _mapController.complete(controller);
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
          // Top Search Bar and Filters
          if (!_isDrawing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 4.0,
                    top: 12.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Search bar
                          Expanded(
                            child: TactileButton(
                              onPressed: () {
                                // TODO: Handle search action
                              },
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.01),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/search.svg',
                                      width: 24,
                                      height: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Search by area, road, village...',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF6B7280),
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Filter button
                          TactileButton(
                            onPressed: () {},
                            child: Align(
                              widthFactor: 0.8,
                              child: SvgPicture.asset(
                                'assets/icons/filter.svg',
                                width: 76,
                                height: 68,
                              ),
                            ),
                          ),
                          // Scan button
                          TactileButton(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.camera,
                                maxWidth: 1000,
                                maxHeight: 1000,
                                imageQuality: 70,
                              );
                              
                              if (image == null) return;
                              
                              final croppedFile = await ImageCropper().cropImage(
                                sourcePath: image.path,
                                compressQuality: 100,
                                uiSettings: [
                                  AndroidUiSettings(
                                    toolbarTitle: 'Crop Document',
                                    toolbarColor: const Color(0xFF5B5FEF),
                                    toolbarWidgetColor: Colors.white,
                                    initAspectRatio: CropAspectRatioPreset.original,
                                    lockAspectRatio: false,
                                    hideBottomControls: false,
                                  ),
                                  IOSUiSettings(
                                    title: 'Crop Document',
                                  ),
                                ],
                              );
                              
                              if (croppedFile == null) return;
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Processing image...')),
                                );
                              }
                              
                              final textRecognizer = TextRecognizer();
                              final inputImage = InputImage.fromFilePath(croppedFile.path);
                              
                              final recognizedText = await textRecognizer.processImage(inputImage);
                              final coordinates = OcrParser.parseRecognizedText(recognizedText);
                              
                              await textRecognizer.close();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                if (coordinates.isNotEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Extracted ${coordinates.length} coordinate(s)!')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No coordinates found. Please try again.')),
                                  );
                                }
                                
                                final result = await showModalBottomSheet<List<LatLng>>(
                                  context: context,
                                  isScrollControlled: true,
                                  useRootNavigator: false,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => UtmLocateBottomSheet(initialCoordinates: coordinates),
                                );
                                
                                if (result != null && result.isNotEmpty && mounted) {
                                  setState(() {
                                    _isDrawing = true;
                                    _isEditingPolygon = true;
                                    _canDraw = false;
                                    _drawnPoints = List.from(result);
                                  });
                                  _updateMapOverlays();
                                  _animateToPolygon(result);
                                }
                              }
                            },
                            child: Align(
                              widthFactor: 0.8,
                              child: SvgPicture.asset(
                                'assets/icons/scan.svg',
                                width: 76,
                                height: 68,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Second Row: Listing Type and Map Type
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Listing Type chip
                          TactileButton(
                            onPressed: () {
                              // TODO: Handle listing type tap
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFF3E49C7),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(24.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.cancel,
                                    color: Color(0xFF3E49C7),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Listing Type',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF3E49C7),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Color(0xFF3E49C7),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Map type icon
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: TactileButton(
                              onPressed: () {
                                setState(() {
                                  if (_currentSkin == MapSkin.defaultMap) {
                                    _currentSkin = MapSkin.satellite;
                                  } else {
                                    _currentSkin = MapSkin.defaultMap;
                                  }
                                });
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: AssetImage(
                                      _currentSkin == MapSkin.satellite
                                          ? 'assets/images/homescreen/mapSatellite.png'
                                          : 'assets/images/homescreen/mapDefault.png',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Plus Icon and Animated Menu (Bottom Left)
          if (!_isDrawing)
            Positioned(
              left: 0,
              bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // Prevent taps from bleeding to map
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnimatedMenuItem(
                    iconPath: 'assets/icons/utm.svg',
                    label: 'Coordinates',
                    onTap: () async {
                      // Close the floating menu first
                      setState(() {
                        _isMenuOpen = false;
                        _animationController.reverse();
                      });
                      final result = await showModalBottomSheet<List<LatLng>>(
                        context: context,
                        isScrollControlled: true,
                        useRootNavigator: false,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const UtmLocateBottomSheet(),
                      );
                      
                      if (result != null && result.isNotEmpty && mounted) {
                        setState(() {
                          _isDrawing = true;
                          _isEditingPolygon = true;
                          _canDraw = false;
                          _drawnPoints = List.from(result);
                        });
                        _updateMapOverlays();
                        
                        final GoogleMapController controller = await _mapController.future;
                        controller.animateCamera(CameraUpdate.newLatLngZoom(result.first, 18));
                      }
                    },
                  ),
                  _buildAnimatedMenuItem(
                    iconPath: 'assets/icons/draw.svg',
                    label: 'Draw',
                    onTap: () {
                      setState(() {
                        _isDrawing = true;
                        _canDraw = false;
                      });
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) setState(() => _canDraw = true);
                      });
                    },
                  ),
                  TactileButton(
                    onPressed: () {
                      setState(() {
                        _isMenuOpen = !_isMenuOpen;
                        if (_isMenuOpen) {
                          _animationController.forward();
                        } else {
                          _animationController.reverse();
                        }
                      });
                    },
                    child: AnimatedRotation(
                      turns: _isMenuOpen ? 0.125 : 0, // 45 degree rotation
                      duration: const Duration(milliseconds: 250),
                      child: SvgPicture.asset(
                        'assets/icons/plus.svg',
                        width: 76,
                        height: 76,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Current Position Icon (Bottom Right)
          if (!_isDrawing)
            Positioned(
              right: 0,
              bottom: 0,
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
            Positioned(
              left: 16,
              bottom: 24,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // Prevent taps from bleeding through to the map
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCircleButton(
                      'assets/icons/revert.svg',
                      onPressed: () {
                        if (_isEditingPolygon) {
                          if (_selectedVertexIndex != null && _drawnPoints.length > 3) {
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
                    ),
                    const SizedBox(height: 12),
                    _buildCircleButton(
                      'assets/icons/bin.svg',
                      onPressed: () {
                        setState(() {
                          _drawnPoints.clear();
                          if (_isEditingPolygon) {
                            _isDrawing = false;
                            _isEditingPolygon = false;
                            _selectedVertexIndex = null;
                            _backupPoints = null; // Deleted!
                            _canDraw = false;
                          }
                          _updateMapOverlays();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (_isDrawing)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {}, // Prevent taps from bleeding through
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TactileButton(
                        onPressed: () {
                          setState(() {
                            _isDrawing = false;
                            _isEditingPolygon = false;
                            _selectedVertexIndex = null;
                            _canDraw = false;
                            if (_backupPoints != null) {
                              _finalizedProperties.add(_backupPoints!);
                              _backupPoints = null;
                            }
                            _drawnPoints.clear();
                            _updateMapOverlays();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TactileButton(
                        onPressed: () {
                          if (_drawnPoints.length >= 3) {
                            setState(() {
                              _isDrawing = false;
                              _isEditingPolygon = false;
                              _selectedVertexIndex = null;
                              _canDraw = false;
                              _finalizedProperties.add(List.from(_drawnPoints));
                              _drawnPoints.clear();
                              _backupPoints = null;
                            });
                            _updateMapOverlays();
                          } else {
                            setState(() {
                              _isDrawing = false;
                              _canDraw = false;
                              _backupPoints = null;
                              _drawnPoints.clear();
                            });
                            _updateMapOverlays();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B5FEF),
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Save',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Add Pin FAB (Right Side)
            if (_isDrawing && !_isEditingPolygon)
              Positioned(
                right: 16,
                bottom: 24,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {}, // Prevent taps from bleeding through to the map
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TactileButton(
                        onPressed: () {
                          if (_currentMapCenter != null) {
                            _mapController.future.then((controller) async {
                              if (_drawnPoints.length >= 3) {
                                final firstPointScreen = await controller.getScreenCoordinate(_drawnPoints.first);
                                final crosshairScreen = await controller.getScreenCoordinate(_currentMapCenter!);
                                
                                final dx = firstPointScreen.x - crosshairScreen.x;
                                final dy = firstPointScreen.y - crosshairScreen.y;
                                final distanceSquared = dx * dx + dy * dy;
                                
                                // Auto-connect if within 40 screen pixels
                                if (distanceSquared <= 40 * 40) {
                                  if (mounted) {
                                    setState(() {
                                      _isDrawing = false;
                                      _canDraw = false;
                                      _finalizedProperties.add(List.from(_drawnPoints));
                                      _drawnPoints.clear();
                                    });
                                    _updateMapOverlays();
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
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5484D),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE5484D).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_location_alt,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 98.0,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1.0)),
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
      onPressed: () {
        setState(() {
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
}
