// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tilomnov/features/property/data/models/property_keyword.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_form_inputs.dart';
import 'package:tilomnov/features/property/presentation/widgets/forms/types/property_type_forms.dart';
import 'package:tilomnov/features/property/presentation/widgets/forms/types/warehouse_property_form.dart';
import 'add_property_page.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/features/property/presentation/property_labels.dart';
import 'package:tilomnov/shared/widgets/media/tinted_svg.dart';

extension AddPropertyPageFormsDynamic on AddPropertyPageState {
  Widget buildMapPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropertySectionTitle(
          title: context.l10n.propertyMapPreview,
          required: false,
        ),
        const SizedBox(height: 8),
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.colors.divider,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: context.colors.border),
          ),
          child: widget.boundaryPoints.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: widget.boundaryPoints.first,
                      zoom: 16,
                    ),
                    zoomControlsEnabled: false,
                    zoomGesturesEnabled: false,
                    scrollGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    myLocationButtonEnabled: false,
                    polygons: {
                      Polygon(
                        polygonId: const PolygonId('preview'),
                        points: widget.boundaryPoints,
                        fillColor: context.colors.accent.withValues(alpha: 0.2),
                        strokeColor: context.colors.accent,
                        strokeWidth: 2,
                      ),
                    },
                    onMapCreated: (controller) {
                      final bounds = boundsFromLatLngList(
                        widget.boundaryPoints,
                      );
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          controller.animateCamera(
                            CameraUpdate.newLatLngBounds(bounds, 30),
                          );
                        }
                      });
                    },
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: context.colors.textHint),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.propertySetPropertyLocation,
                      style: GoogleFonts.inter(
                        color: context.colors.textHint,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.propertyLocationBoundary,
          style: GoogleFonts.inter(
            color: context.colors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: context.colors.textSecondary,
                ),
                label: Text(
                  context.l10n.homeLocateProperty,
                  style: GoogleFonts.inter(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: context.colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: TintedSvg(
                  'assets/icons/draw_property.svg',
                  width: 18,
                  height: 18,
                  color: context.colors.onPrimary,
                ),
                label: Text(
                  context.l10n.propertyDrawingProperty,
                  style: GoogleFonts.inter(
                    color: context.colors.onPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildKeywordsWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: PropertyKeyword.all.map((kw) {
        final isSelected = selectedKeywords.contains(kw.code);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedKeywords.remove(kw.code);
              } else {
                selectedKeywords.add(kw.code);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.colors.accent.withValues(alpha: 0.05)
                  : context.colors.surface,
              border: Border.all(
                color: isSelected
                    ? context.colors.accent
                    : context.colors.border,
              ),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TintedSvg(
                  kw.iconPath,
                  width: 16,
                  height: 16,
                  color: isSelected
                      ? context.colors.accent
                      : context.colors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  propertyKeywordLabel(context.l10n, kw.code),
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? context.colors.accent
                        : context.colors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  Widget buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.border, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            iconPath: 'assets/icons/explore.svg',
            label: context.l10n.navExplore,
            isSelected: true,
          ),
          _buildNavItem(
            iconPath: 'assets/icons/saved.svg',
            label: context.l10n.navSaved,
          ),
          _buildNavItem(
            iconPath: 'assets/icons/chat.svg',
            label: context.l10n.navChat,
          ),
          _buildNavItem(
            iconPath: 'assets/icons/property.svg',
            label: context.l10n.navMyProperties,
          ),
          _buildNavItem(
            iconPath: 'assets/icons/user.svg',
            label: context.l10n.accountDefaultName,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String iconPath,
    required String label,
    bool isSelected = false,
  }) {
    final color = isSelected ? context.colors.accent : context.colors.textMuted;
    return SizedBox(
      width: 70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TintedSvg(iconPath, width: 24, height: 24, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildDynamicFields() {
    void updateState(VoidCallback fn) {
      setState(fn);
    }

    if (selectedPropertyType == 'Land' || selectedPropertyType.isEmpty) {
      return LandPropertyForm(state: this, updateState: updateState);
    } else if (selectedPropertyType == 'House') {
      return HousePropertyForm(state: this, updateState: updateState);
    } else if (selectedPropertyType == 'Warehouse') {
      return WarehousePropertyForm(state: this, updateState: updateState);
    } else if (selectedPropertyType == 'Building') {
      return BuildingPropertyForm(state: this, updateState: updateState);
    } else if (selectedPropertyType == 'Condo') {
      return CondoPropertyForm(state: this, updateState: updateState);
    } else if (selectedPropertyType == 'Borey') {
      return BoreyPropertyForm(state: this, updateState: updateState);
    } else if (selectedPropertyType == 'Business for Sale') {
      return BusinessPropertyForm(state: this, updateState: updateState);
    }

    return const SizedBox.shrink();
  }
}
