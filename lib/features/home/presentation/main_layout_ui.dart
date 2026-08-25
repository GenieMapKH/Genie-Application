// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
part of 'main_layout.dart';

extension MainLayoutUI on _MainLayoutState {
  Widget _buildMainLayout(BuildContext context) {
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
                      initialCameraPosition: _MainLayoutState._initialPosition,
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
}
