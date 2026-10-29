import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tilomnov/features/property/data/models/property_model.dart';

enum MapSkin { defaultMap, satellite }

class MapState {
  // View State (the live camera lives in `mapCameraProvider`)
  final MapSkin currentSkin;

  /// Index into the locally drawn [finalizedProperties] that should show its
  /// measurement overlay. Backend-backed properties are highlighted via
  /// `propertyCarouselProvider` instead, since they have a model to select.
  final int? highlightedLocalPolygon;

  // Drawing State
  final bool isDrawing;
  final bool isEditingPolygon;
  final int? selectedVertexIndex;

  /// The corner being dragged.
  final int? draggingVertex;

  /// Where the dragged handle was when the drag began. The map keeps that
  /// handle exactly as it was until the drop: updating a marker mid-drag
  /// would snap it back under the finger.
  final LatLng? dragOrigin;

  /// When the dragged corner was pulled out of an edge's "+" handle: that
  /// edge's index, so the map keeps the handle the finger is holding.
  final int? dragStartEdge;

  /// The saved listing whose boundary is being edited; null while drawing a
  /// new one or editing a local polygon.
  final PropertyModel? editingProperty;

  // Data State
  final List<LatLng> drawnPoints;
  final List<LatLng>? backupPoints;
  final List<List<LatLng>> finalizedProperties;

  const MapState({
    this.currentSkin = MapSkin.defaultMap,
    this.highlightedLocalPolygon,
    this.isDrawing = false,
    this.isEditingPolygon = false,
    this.selectedVertexIndex,
    this.draggingVertex,
    this.dragOrigin,
    this.dragStartEdge,
    this.editingProperty,
    this.drawnPoints = const [],
    this.backupPoints,
    this.finalizedProperties = const [],
  });

  MapState copyWith({
    MapSkin? currentSkin,
    int? highlightedLocalPolygon,
    bool? isDrawing,
    bool? isEditingPolygon,
    int? selectedVertexIndex,
    int? draggingVertex,
    LatLng? dragOrigin,
    int? dragStartEdge,
    PropertyModel? editingProperty,
    List<LatLng>? drawnPoints,
    List<LatLng>? backupPoints,
    List<List<LatLng>>? finalizedProperties,
    bool clearHighlightedLocalPolygon = false,
    bool clearSelectedVertex = false,
    bool clearBackupPoints = false,
    bool clearDrag = false,
    bool clearEditingProperty = false,
  }) {
    return MapState(
      currentSkin: currentSkin ?? this.currentSkin,
      highlightedLocalPolygon: clearHighlightedLocalPolygon
          ? null
          : (highlightedLocalPolygon ?? this.highlightedLocalPolygon),
      isDrawing: isDrawing ?? this.isDrawing,
      isEditingPolygon: isEditingPolygon ?? this.isEditingPolygon,
      selectedVertexIndex: clearSelectedVertex
          ? null
          : (selectedVertexIndex ?? this.selectedVertexIndex),
      draggingVertex: clearDrag
          ? null
          : (draggingVertex ?? this.draggingVertex),
      dragOrigin: clearDrag ? null : (dragOrigin ?? this.dragOrigin),
      dragStartEdge: clearDrag ? null : (dragStartEdge ?? this.dragStartEdge),
      editingProperty: clearEditingProperty
          ? null
          : (editingProperty ?? this.editingProperty),
      drawnPoints: drawnPoints ?? this.drawnPoints,
      backupPoints: clearBackupPoints
          ? null
          : (backupPoints ?? this.backupPoints),
      finalizedProperties: finalizedProperties ?? this.finalizedProperties,
    );
  }
}

class MapStateNotifier extends StateNotifier<MapState> {
  MapStateNotifier() : super(const MapState());

  void setSkin(MapSkin skin) {
    state = state.copyWith(currentSkin: skin);
  }

  void toggleSkin() {
    state = state.copyWith(
      currentSkin: state.currentSkin == MapSkin.defaultMap
          ? MapSkin.satellite
          : MapSkin.defaultMap,
    );
  }

  void highlightLocalPolygon(int? index) {
    state = state.copyWith(
      highlightedLocalPolygon: index,
      clearHighlightedLocalPolygon: index == null,
    );
  }

  // Drawing Actions
  void startDrawing({List<LatLng>? initialPoints}) {
    state = state.copyWith(
      isDrawing: true,
      isEditingPolygon: initialPoints != null,
      drawnPoints: initialPoints ?? [],
      backupPoints: initialPoints != null ? List.from(initialPoints) : null,
      clearSelectedVertex: true,
      clearHighlightedLocalPolygon: true,
      clearDrag: true,
      clearEditingProperty: true,
    );
  }

  void cancelDrawing() {
    final List<List<LatLng>> newFinalized = List.from(
      state.finalizedProperties,
    );
    // A saved listing is still on the server unchanged; only a local polygon
    // needs putting back.
    if (state.backupPoints != null && state.editingProperty == null) {
      newFinalized.add(state.backupPoints!);
    }

    state = state.copyWith(
      isDrawing: false,
      isEditingPolygon: false,
      drawnPoints: [],
      finalizedProperties: newFinalized,
      clearSelectedVertex: true,
      clearBackupPoints: true,
      clearDrag: true,
      clearEditingProperty: true,
    );
  }

  void clearDrawing() {
    state = state.copyWith(
      drawnPoints: [],
      isDrawing: state.isEditingPolygon ? false : state.isDrawing,
      isEditingPolygon: state.isEditingPolygon ? false : state.isEditingPolygon,
      clearSelectedVertex: true,
      clearBackupPoints: state.isEditingPolygon,
      clearDrag: true,
      clearEditingProperty: state.isEditingPolygon,
    );
  }

  void closePolygonForEditing() {
    if (state.drawnPoints.length < 3) return;
    state = state.copyWith(isEditingPolygon: true);
  }

  void addPoint(LatLng point) {
    state = state.copyWith(drawnPoints: [...state.drawnPoints, point]);
  }

  void removeLastPoint() {
    if (state.drawnPoints.isNotEmpty) {
      final newPoints = List<LatLng>.from(state.drawnPoints)..removeLast();
      state = state.copyWith(drawnPoints: newPoints);
    }
  }

  void removeVertex(int index) {
    if (index >= 0 && index < state.drawnPoints.length) {
      final newPoints = List<LatLng>.from(state.drawnPoints)..removeAt(index);
      state = state.copyWith(drawnPoints: newPoints, clearSelectedVertex: true);
    }
  }

  void updatePoint(int index, LatLng newPosition) {
    if (index >= 0 && index < state.drawnPoints.length) {
      final newPoints = List<LatLng>.from(state.drawnPoints);
      newPoints[index] = newPosition;
      state = state.copyWith(drawnPoints: newPoints);
    }
  }

  void insertPoint(int index, LatLng point) {
    final newPoints = List<LatLng>.from(state.drawnPoints)
      ..insert(index, point);
    state = state.copyWith(drawnPoints: newPoints, selectedVertexIndex: index);
  }

  /// Starts dragging corner [index]. It is selected on the drop, not now,
  /// so its handle stays untouched while it moves.
  void startVertexDrag(int index) {
    if (index < 0 || index >= state.drawnPoints.length) return;
    state = state.copyWith(
      draggingVertex: index,
      dragOrigin: state.drawnPoints[index],
    );
  }

  /// Pulls a new corner out of edge [edge] (between corners `edge` and
  /// `edge + 1`) at its "+" handle's position [handle], and starts dragging
  /// it from there.
  void startEdgeDrag(int edge, LatLng handle) {
    final index = edge + 1;
    final newPoints = List<LatLng>.from(state.drawnPoints)
      ..insert(index, handle);
    state = state.copyWith(
      drawnPoints: newPoints,
      draggingVertex: index,
      dragOrigin: handle,
      dragStartEdge: edge,
      // The old selection's index may have shifted; the new corner is
      // selected on the drop.
      clearSelectedVertex: true,
    );
  }

  /// Drops the dragged corner [index] at [point] and selects it.
  void endVertexDrag(int index, LatLng point) {
    final newPoints = List<LatLng>.from(state.drawnPoints);
    if (index >= 0 && index < newPoints.length) newPoints[index] = point;
    state = state.copyWith(
      drawnPoints: newPoints,
      selectedVertexIndex: index,
      clearDrag: true,
    );
  }

  void selectVertex(int? index) {
    state = state.copyWith(
      selectedVertexIndex: index,
      clearSelectedVertex: index == null,
    );
  }

  /// Edits the boundary [propertyPoints]: of the saved listing [property], or
  /// of a local polygon when it is null.
  void editProperty(List<LatLng> propertyPoints, PropertyModel? property) {
    final newFinalized = List<List<LatLng>>.from(state.finalizedProperties)
      ..removeWhere((p) => p.toString() == propertyPoints.toString());

    state = state.copyWith(
      drawnPoints: List.from(propertyPoints),
      backupPoints: List.from(propertyPoints),
      finalizedProperties: newFinalized,
      isDrawing: true,
      isEditingPolygon: true,
      editingProperty: property,
      clearEditingProperty: property == null,
      clearSelectedVertex: true,
      clearDrag: true,
    );
  }

  void finalizeDrawing() {
    // A saved listing's new boundary comes back with the refreshed listings.
    final newFinalized = List<List<LatLng>>.from(state.finalizedProperties);
    if (state.editingProperty == null) {
      newFinalized.add(List.from(state.drawnPoints));
    }

    state = state.copyWith(
      isDrawing: false,
      isEditingPolygon: false,
      drawnPoints: [],
      finalizedProperties: newFinalized,
      clearSelectedVertex: true,
      clearBackupPoints: true,
      clearDrag: true,
      clearEditingProperty: true,
    );
  }
}

final mapStateProvider = StateNotifierProvider<MapStateNotifier, MapState>((
  ref,
) {
  return MapStateNotifier();
});
