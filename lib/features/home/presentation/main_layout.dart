import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:genie/shared/widgets/tactile_button.dart';
import 'package:genie/features/home/utils/map_measurements.dart';
import 'package:genie/features/home/utils/svg_marker.dart';
import 'package:genie/features/home/utils/map_markers.dart';

enum MapSkin { defaultMap, satellite, leaflet }

class OSMTileProvider implements TileProvider {
  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    try {
      final url = 'https://tile.openstreetmap.org/$zoom/$x/$y.png';
      // OSM requires a valid User-Agent header or they block requests, especially on Android
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'GenieApp/1.0.0 (Flutter)'},
      );
      if (response.statusCode == 200) {
        return Tile(256, 256, response.bodyBytes);
      }
      return TileProvider.noTile;
    } catch (e) {
      return TileProvider.noTile;
    }
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  MapSkin _currentSkin = MapSkin.defaultMap;
  final TileProvider _osmTileProvider = OSMTileProvider();

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  bool _isMenuOpen = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  // Drawing Mode States
  bool _isDrawing = false;
  bool _canDraw = false;
  List<LatLng> _drawnPoints = [];
  List<LatLng>? _backupPoints;
  List<List<LatLng>> _finalizedProperties = [];
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _pinIcon;
  BitmapDescriptor? _greenDotIcon;
  BitmapDescriptor? _detailedPropertyIcon;
  double _currentZoom = 14.4746;
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
    _updateMapOverlays();
  }

  @override
  void dispose() {
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
                    child: SvgPicture.asset(iconPath, width: 24, height: 24),
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
        width: 44,
        height: 44,
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
        child: Center(child: SvgPicture.asset(iconPath, width: 24, height: 24)),
      ),
    );
  }

  void _onMapTapped(LatLng position) {
    if (!_isDrawing || !_canDraw) return;

    setState(() {
      _drawnPoints.add(position);
    });
    _updateMapOverlays();
  }

  Future<void> _updateMapOverlays() async {
    final Set<Marker> newMarkers = {};
    final Set<Polyline> newPolylines = {};
    final Set<Polygon> newPolygons = {};

    // Render all finalized properties
    for (int pIndex = 0; pIndex < _finalizedProperties.length; pIndex++) {
      final List<LatLng> propPoints = _finalizedProperties[pIndex];
      if (propPoints.length >= 3) {
        final bool isZoomedIn = _currentZoom > _zoomThreshold;

        if (isZoomedIn) {
          newPolygons.add(
            Polygon(
              polygonId: PolygonId('final_polygon_$pIndex'),
              points: propPoints,
              strokeColor: Colors.white,
              strokeWidth: 2,
              fillColor: Colors.transparent,
            ),
          );
          final measurements = calculateMeasurements(propPoints);

          // Add vertex number markers
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
              ),
            );
          }

          // Add edge length markers and Area marker
          if (measurements != null && measurements.sides.isNotEmpty) {
            for (int i = 0; i < propPoints.length; i++) {
              final LatLng p1 = propPoints[i];
              final LatLng p2 = propPoints[(i + 1) % propPoints.length];
              final LatLng midPoint = LatLng(
                (p1.latitude + p2.latitude) / 2,
                (p1.longitude + p2.longitude) / 2,
              );
              final lengthStr = '${measurements.sides[i].toStringAsFixed(0)} m';
              final lengthIcon = await DynamicMapMarkers.createTextMarker(
                lengthStr,
              );

              newMarkers.add(
                Marker(
                  markerId: MarkerId('length_${pIndex}_$i'),
                  position: midPoint,
                  icon: lengthIcon,
                  anchor: const Offset(0.5, 0.5),
                ),
              );
            }

            // Area marker centroid
            double sumLat = 0, sumLng = 0;
            for (var p in propPoints) {
              sumLat += p.latitude;
              sumLng += p.longitude;
            }
            final LatLng centroid = LatLng(
              sumLat / propPoints.length,
              sumLng / propPoints.length,
            );
            final areaStr = '${measurements.area.toStringAsFixed(0)} m²';
            final areaIcon = await DynamicMapMarkers.createTextMarker(
              areaStr,
              isArea: true,
            );
            newMarkers.add(
              Marker(
                markerId: MarkerId('area_marker_$pIndex'),
                position: centroid,
                icon: areaIcon,
                anchor: const Offset(0.5, 0.5),
              ),
            );
          }

          // Add Edit marker
          final editIcon = await DynamicMapMarkers.createEditMarker();
          newMarkers.add(
            Marker(
              markerId: MarkerId('edit_$pIndex'),
              position: propPoints[0], // Anchor it to the first point
              icon: editIcon,
              anchor: const Offset(1.2, 1.2), // Offset to the top-left of point 1
              consumeTapEvents: true,
              onTap: () {
                setState(() {
                  _drawnPoints = List.from(propPoints);
                  _backupPoints = List.from(propPoints);
                  _finalizedProperties.remove(propPoints);
                  _isDrawing = true;
                  _canDraw = false;
                });
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) setState(() => _canDraw = true);
                });
                _updateMapOverlays();
              },
            ),
          );
        } else {
          // Zoomed out! Show green dot at centroid.
          double sumLat = 0, sumLng = 0;
          for (var p in propPoints) {
            sumLat += p.latitude;
            sumLng += p.longitude;
          }
          final LatLng centroid = LatLng(
            sumLat / propPoints.length,
            sumLng / propPoints.length,
          );

          newMarkers.add(
            Marker(
              markerId: MarkerId('final_green_dot_$pIndex'),
              position: centroid,
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
    }

    if (_isDrawing) {
      for (int i = 0; i < _drawnPoints.length; i++) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('point_$i'),
            position: _drawnPoints[i],
            draggable: true,
            consumeTapEvents: true,
            onTap: () {
              if (i == 0 && _drawnPoints.length >= 3) {
                // Tapping the first point closes the polygon!
                setState(() {
                  _isDrawing = false;
                  _canDraw = false;
                  _finalizedProperties.add(List.from(_drawnPoints));
                  _drawnPoints.clear();
                });
                _updateMapOverlays();
              }
            },
            onDragEnd: (newPosition) {
              setState(() {
                _drawnPoints[i] = newPosition;
              });
              _updateMapOverlays();
            },
            icon:
                _pinIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            anchor: const Offset(0.5, 0.126),
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
    } else {
      // Normal Mode: Show Property Markers
      for (int i = 0; i < _dummyProperties.length; i++) {
        final bool isZoomedIn = _currentZoom > _zoomThreshold;
        final icon = isZoomedIn
            ? (_detailedPropertyIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ))
            : (_greenDotIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ));

        newMarkers.add(
          Marker(
            markerId: MarkerId('property_$i'),
            position: _dummyProperties[i],
            icon: icon,
            anchor: const Offset(0.5, 0.5),
          ),
        );
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
          Positioned.fill(
            child: GoogleMap(
              mapType: _currentSkin == MapSkin.satellite
                  ? MapType.satellite
                  : (_currentSkin == MapSkin.leaflet
                        ? MapType.none
                        : MapType.normal),
              initialCameraPosition: _initialPosition,
              onMapCreated: (GoogleMapController controller) {
                _mapController.complete(controller);
              },
              onCameraMove: (CameraPosition position) {
                final bool wasZoomedIn = _currentZoom > _zoomThreshold;
                final bool isZoomedIn = position.zoom > _zoomThreshold;
                _currentZoom = position.zoom;

                if (wasZoomedIn != isZoomedIn && !_isDrawing) {
                  _updateMapOverlays();
                }
              },
              onTap: _onMapTapped,
              markers: _markers,
              polygons: _polygons,
              polylines: _polylines,
              tileOverlays: _currentSkin == MapSkin.leaflet
                  ? {
                      TileOverlay(
                        tileOverlayId: const TileOverlayId('osm_tiles'),
                        tileProvider: _osmTileProvider,
                      ),
                    }
                  : {},
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              minMaxZoomPreference: const MinMaxZoomPreference(0, 24),
              compassEnabled: false,
              mapToolbarEnabled: false,
              myLocationEnabled: false,
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
                            onPressed: () {},
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
                                  } else if (_currentSkin ==
                                      MapSkin.satellite) {
                                    _currentSkin = MapSkin.leaflet;
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
                                          : (_currentSkin == MapSkin.leaflet
                                                ? 'assets/images/homescreen/mapLeaflet.jpg'
                                                : 'assets/images/homescreen/mapDefault.png'),
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
                    onTap: () {
                      // TODO: Handle Coordinates action
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
                        if (_drawnPoints.isNotEmpty) {
                          setState(() {
                            _drawnPoints.removeLast();
                            _updateMapOverlays();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildCircleButton(
                      'assets/icons/bin.svg',
                      onPressed: () {
                        setState(() {
                          _drawnPoints.clear();
                          _updateMapOverlays();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCircleButton(
                          'assets/icons/draw.svg',
                          onPressed: () {},
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
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
                            'Draw',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF4B5563),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
