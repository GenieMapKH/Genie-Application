// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:genie/features/home/presentation/widgets/map_top_controls.dart';
import 'package:genie/features/home/presentation/widgets/map_floating_menu.dart';
import 'package:genie/features/home/presentation/widgets/drawing_controls_panel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:genie/shared/widgets/tactile_button.dart';
import 'package:genie/features/property/presentation/screens/my_properties_page.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import 'package:genie/features/profile/presentation/screens/user_profile_page.dart';
import 'package:genie/core/storage/map_storage.dart';
import 'main_layout.dart';
import 'main_layout_map_logic.dart';
import 'main_layout_nav.dart';

extension MainLayoutUI on MainLayoutState {
  Widget buildMainLayout(BuildContext context) {
    ref.listen(propertiesProvider, (previous, next) {
      if (next.hasValue && next.value != previous?.value) {
        updateMapOverlays();
      }
    });
    ref.listen(publicPropertiesProvider, (previous, next) {
      if (next.hasValue && next.value != previous?.value) {
        updateMapOverlays();
      }
    });
    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (currentIndex != 0) {
          setState(() {
            previousIndex = currentIndex;
            currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        extendBody: true, // Allow map to show through the transparent nav bar
        body: Stack(
          children: [
            IgnorePointer(
              ignoring: currentIndex == 3 || currentIndex == 4,
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
                      mapType: currentSkin == MapSkin.satellite
                          ? MapType.hybrid
                          : MapType.normal,
                      initialCameraPosition: MainLayoutState.initialPosition,
                      onMapCreated: (GoogleMapController controller) {
                        if (!mapController.isCompleted) {
                          mapController.complete(controller);
                        }
                        updateMapOverlays();
                      },
                      onCameraMove: (CameraPosition position) {
                        currentMapCenter = position.target;
                        final double clusterZoomThreshold = 13.0;
                        final double edgeZoomThreshold = 18.0;

                        int getZoomState(double zoom) {
                          if (zoom <= clusterZoomThreshold) return 1;
                          if (zoom <= zoomThreshold) return 2;
                          if (zoom <= edgeZoomThreshold) return 3;
                          return 4;
                        }

                        final int prevZoomState = getZoomState(currentZoom);
                        final int newZoomState = getZoomState(position.zoom);

                        currentZoom = position.zoom;

                        if (prevZoomState != newZoomState && !isDrawing) {
                          updateMapOverlays();
                        }
                      },
                      onCameraIdle: () async {
                        if (currentMapCenter != null) {
                          MapStorage.saveLastPosition(
                            CameraPosition(
                              target: currentMapCenter!,
                              zoom: currentZoom,
                            ),
                          );
                        }
                        if (isDrawing &&
                            !isEditingPolygon &&
                            drawnPoints.length >= 3 &&
                            currentMapCenter != null) {
                          final controller = await mapController.future;
                          final firstPointScreen = await controller
                              .getScreenCoordinate(drawnPoints.first);
                          final crosshairScreen = await controller
                              .getScreenCoordinate(currentMapCenter!);

                          final dx = firstPointScreen.x - crosshairScreen.x;
                          final dy = firstPointScreen.y - crosshairScreen.y;
                          final distanceSquared = dx * dx + dy * dy;

                          // Magnetically snap the camera to the first pin if within ~100 screen pixels
                          // The > 5 check prevents an infinite snapping loop if we are already centered
                          if (distanceSquared <= 100 * 100 &&
                              distanceSquared > 5) {
                            controller.animateCamera(
                              CameraUpdate.newLatLng(drawnPoints.first),
                            );
                          }
                        }
                      },
                      onTap: onMapTapped,
                      markers: markers,
                      polygons: polygons,
                      polylines: polylines,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      minMaxZoomPreference: const MinMaxZoomPreference(0, null),
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      myLocationEnabled: true,
                    ),
                  ),
                  // Crosshair
                  if (isDrawing && !isEditingPolygon)
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
                  if (!isDrawing)
                    MapTopControls(
                      currentSkin: currentSkin,
                      onToggleMapType: () {
                        setState(() {
                          if (currentSkin == MapSkin.defaultMap) {
                            currentSkin = MapSkin.satellite;
                          } else {
                            currentSkin = MapSkin.defaultMap;
                          }
                        });
                      },
                      onCoordinatesScanned: (result) {
                        if (mounted) {
                          setState(() {
                            isDrawing = true;
                            isEditingPolygon = true;
                            // canDraw = false;
                            drawnPoints = List.from(result);
                          });
                          updateMapOverlays();
                          mapController.future.then((controller) {
                            controller.animateCamera(
                              CameraUpdate.newLatLngZoom(result.first, 21.5),
                            );
                          });
                        }
                      },
                    ),
                  // Plus Icon and Animated Menu (Bottom Left)
                  if (!isDrawing)
                    MapFloatingMenu(
                      onDrawPressed: () {
                        setState(() {
                          isDrawing = true;
                          // canDraw = false;
                        });
                        Future.delayed(const Duration(milliseconds: 300), () {
                          // if (mounted) setState(() => canDraw = true);
                        });
                      },
                      onCoordinatesScanned: (result) {
                        if (mounted) {
                          setState(() {
                            isDrawing = true;
                            isEditingPolygon = true;
                            // canDraw = false;
                            drawnPoints = List.from(result);
                          });
                          updateMapOverlays();
                          mapController.future.then((controller) {
                            controller.animateCamera(
                              CameraUpdate.newLatLngZoom(result.first, 21.5),
                            );
                          });
                        }
                      },
                    ),
                  // Current Position Icon (Bottom Right)
                  if (!isDrawing)
                    Positioned(
                      right: 0,
                      bottom:
                          110, // Offset for extendBody bottom navigation bar
                      child: TactileButton(
                        onPressed: goToCurrentPosition,
                        child: SvgPicture.asset(
                          'assets/icons/current_position.svg',
                          width: 76,
                          height: 76,
                        ),
                      ),
                    ),
                  // Drawing UI Controls
                  if (isDrawing)
                    DrawingControlsPanel(
                      isEditingPolygon: isEditingPolygon,
                      onRevertPressed: () {
                        if (isEditingPolygon) {
                          if (selectedVertexIndex != null &&
                              drawnPoints.length > 3) {
                            setState(() {
                              drawnPoints.removeAt(selectedVertexIndex!);
                              selectedVertexIndex = null;
                              updateMapOverlays();
                            });
                          }
                        } else {
                          if (drawnPoints.isNotEmpty) {
                            setState(() {
                              drawnPoints.removeLast();
                              updateMapOverlays();
                            });
                          }
                        }
                      },
                      onDeletePressed: () {
                        setState(() {
                          drawnPoints.clear();
                          if (isEditingPolygon) {
                            isDrawing = false;
                            isEditingPolygon = false;
                            selectedVertexIndex = null;
                            backupPoints = null; // Deleted!
                            // canDraw = false;
                          }
                          updateMapOverlays();
                        });
                      },
                      onCancelPressed: () {
                        setState(() {
                          isDrawing = false;
                          isEditingPolygon = false;
                          selectedVertexIndex = null;
                          // canDraw = false;
                          if (backupPoints != null) {
                            finalizedProperties.add(backupPoints!);
                            backupPoints = null;
                          }
                          drawnPoints.clear();
                          updateMapOverlays();
                        });
                      },
                      onSavePressed: () {
                        if (drawnPoints.length >= 3) {
                          showAddPropertyForm();
                        } else {
                          setState(() {
                            isDrawing = false;
                            // canDraw = false;
                            backupPoints = null;
                            drawnPoints.clear();
                          });
                          updateMapOverlays();
                        }
                      },
                      onAddPinPressed: () {
                        if (currentMapCenter != null) {
                          mapController.future.then((controller) async {
                            if (drawnPoints.length >= 3) {
                              final firstPointScreen = await controller
                                  .getScreenCoordinate(drawnPoints.first);
                              final crosshairScreen = await controller
                                  .getScreenCoordinate(currentMapCenter!);

                              final dx = firstPointScreen.x - crosshairScreen.x;
                              final dy = firstPointScreen.y - crosshairScreen.y;
                              final distanceSquared = dx * dx + dy * dy;

                              // Auto-connect if within 150 screen pixels
                              if (distanceSquared <= 150 * 150) {
                                if (mounted) {
                                  closePolygonForEditing();
                                }
                                return;
                              }
                            }

                            if (mounted) {
                              setState(() {
                                drawnPoints.add(currentMapCenter!);
                                updateMapOverlays();
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
              color: (currentIndex >= 3 && previousIndex >= 3)
                  ? Colors.white
                  : Colors.transparent,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  final key = child.key as ValueKey<String>?;
                  final currentKey = currentIndex == 3
                      ? 'my_properties'
                      : currentIndex == 4
                      ? 'user_profile'
                      : 'empty';
                  final bool isIncoming = key?.value == currentKey;

                  Offset beginOffset;
                  if (currentIndex > previousIndex) {
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
                child: currentIndex == 3
                    ? MyPropertiesPage(
                        key: const ValueKey('my_properties'),
                        isEmbedded: true,
                        onBackPressed: () => setState(() {
                          previousIndex = currentIndex;
                          currentIndex = 0;
                        }),
                      )
                    : currentIndex == 4
                    ? UserProfilePage(
                        key: const ValueKey('user_profile'),
                        isEmbedded: true,
                        onBackPressed: () => setState(() {
                          previousIndex = currentIndex;
                          currentIndex = 0;
                        }),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ),
          ],
        ),
        bottomNavigationBar: buildBottomNavigationBar(),
      ),
    );
  }
}
