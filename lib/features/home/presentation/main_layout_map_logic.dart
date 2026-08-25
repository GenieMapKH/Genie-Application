// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
part of 'main_layout.dart';

extension MainLayoutMapLogic on _MainLayoutState {
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
}
