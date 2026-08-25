// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
part of 'add_property_page.dart';

extension AddPropertyPageFormsDynamic on _AddPropertyPageState {
  Widget _buildMapPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PropertySectionTitle(title: 'Map Preview', required: false),
        const SizedBox(height: 8),
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: const Color(0xFFE5E7EB)),
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
                        fillColor: const Color(
                          0xFF5B5FEF,
                        ).withValues(alpha: 0.2),
                        strokeColor: const Color(0xFF5B5FEF),
                        strokeWidth: 2,
                      ),
                    },
                    onMapCreated: (controller) {
                      final bounds = _boundsFromLatLngList(
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
                    const Icon(Icons.map, size: 48, color: Color(0xFF9CA3AF)),
                    const SizedBox(height: 8),
                    Text(
                      'Set Property Location',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        Text(
          'Location & Boundary',
          style: GoogleFonts.inter(
            color: const Color(0xFF6B7280),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Color(0xFF374151),
                ),
                label: Text(
                  'Locate Property',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF374151),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
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
                icon: SvgPicture.asset(
                  'assets/icons/draw_property.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                label: Text(
                  'Drawing Property',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B5FEF),
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

  Widget _buildKeywordsWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: _keywords.map((kw) {
        final isSelected = _selectedKeywords.contains(kw['name']);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedKeywords.remove(kw['name']);
              } else {
                _selectedKeywords.add(kw['name']);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF5B5FEF).withValues(alpha: 0.05)
                  : Colors.white,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF5B5FEF)
                    : const Color(0xFFE5E7EB),
              ),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  kw['iconPath'],
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    isSelected
                        ? const Color(0xFF5B5FEF)
                        : const Color(0xFF6B7280),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  kw['name'],
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? const Color(0xFF5B5FEF)
                        : const Color(0xFF4B5563),
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

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
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

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1.0)),
      ),
      padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            iconPath: 'assets/icons/explore.svg',
            label: 'Explore',
            isSelected: true,
          ),
          _buildNavItem(iconPath: 'assets/icons/saved.svg', label: 'Saved'),
          _buildNavItem(iconPath: 'assets/icons/chat.svg', label: 'Chat'),
          _buildNavItem(
            iconPath: 'assets/icons/property.svg',
            label: 'My Properties',
          ),
          _buildNavItem(iconPath: 'assets/icons/user.svg', label: 'User'),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String iconPath,
    required String label,
    bool isSelected = false,
  }) {
    final color = isSelected
        ? const Color(0xFF5B5FEF)
        : const Color(0xFF6B7280);
    return SizedBox(
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

  Widget _buildDefaultPriceListingSettings() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: PropertyTextField(
            label: 'Price',
            required: true,
            controller: _priceController,
            hintText: 'Enter selling price (USD)',
            hasError:
                _hasAttemptedSubmit && _priceController.text.trim().isEmpty,
            focusKey: _priceKey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDropdown(
            label: 'Listing Settings',
            required: true,
            value: _selectedListingSetting,
            items: ['Sale', 'Rent', 'To Let'],
            hasError: _hasAttemptedSubmit && _selectedListingSetting.isEmpty,
            focusKey: _listingSettingsKey,
            onChanged: (val) {
              if (val != null) setState(() => _selectedListingSetting = val);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicFields() {
    List<Widget> fields = [];
    void addSpacing() => fields.add(const SizedBox(height: 16));

    if (_selectedPropertyType == 'Land' || _selectedPropertyType.isEmpty) {
      fields.add(_buildDefaultPriceListingSettings());
      addSpacing();
      fields.add(_buildLandSizeField(isLandType: true));
      addSpacing();
      fields.add(_buildTitleTypeField());
    } else if (_selectedPropertyType == 'House' ||
        _selectedPropertyType == 'Warehouse') {
      fields.add(_buildDefaultPriceListingSettings());
      addSpacing();
      fields.add(_buildLandSizeField());
      addSpacing();
      fields.add(_buildBuildingSizeField());
      addSpacing();
      fields.add(_buildBedroomsField());
      addSpacing();
      fields.add(_buildBathroomsField());
      addSpacing();
      fields.add(_buildFloorsField());
      addSpacing();
      fields.add(_buildParkingField());
      addSpacing();
      fields.add(_buildFurnishedField());
      addSpacing();
      fields.add(_buildTitleTypeField());
    } else if (_selectedPropertyType == 'Building') {
      fields.add(_buildDefaultPriceListingSettings());
      addSpacing();
      fields.add(_buildBuildingTypeField());
      addSpacing();
      fields.add(_buildLandSizeField());
      addSpacing();
      fields.add(_buildBuildingSizeField());
      addSpacing();
      fields.add(_buildNumberofFloorsField());
      addSpacing();
      fields.add(_buildTotalUnitsField());
      addSpacing();
      fields.add(_buildParkingField());
      addSpacing();
      fields.add(_buildTitleTypeField());
    } else if (_selectedPropertyType == 'Condo') {
      fields.add(_buildDefaultPriceListingSettings());
      addSpacing();
      fields.add(_buildUnitSizeField());
      addSpacing();
      fields.add(_buildFloorNumberField());
      addSpacing();
      fields.add(_buildTotalFloorsField());
      addSpacing();
      fields.add(_buildBedroomsField(isCondo: true));
      addSpacing();
      fields.add(_buildBathroomsField());
      addSpacing();
      fields.add(_buildBalconyField());
      addSpacing();
      fields.add(_buildFurnishedField());
      addSpacing();
      fields.add(_buildCompletionStatusField());
      addSpacing();
      fields.add(_buildViewTypeField());
      addSpacing();
      fields.add(_buildMaintenanceFeeField());
      addSpacing();
      fields.add(_buildTitleTypeField());
    } else if (_selectedPropertyType == 'Borey') {
      fields.add(
        PropertyTextField(
          label: 'Developer Name',
          required: false,
          controller: _developerNameController,
          hintText: 'Example: ABC Development Co., Ltd',
        ),
      );
      addSpacing();
      fields.add(
        PropertyTextField(
          label: 'Project Name',
          required: false,
          controller: _projectNameController,
          hintText: 'Project name',
          infoText: 'Official name of the development project',
        ),
      );
      addSpacing();
      fields.add(_buildProjectTypeField());
      addSpacing();
      fields.add(
        PropertyTextField(
          label: 'Total Project Area',
          required: false,
          controller: _totalProjectAreaController,
          hintText: 'Enter total land size',
          infoText: 'Total land area of entire project',
        ),
      );
      addSpacing();
      fields.add(
        PropertyTextField(
          label: 'Total Units',
          required: false,
          controller: _totalUnitsTextController,
          hintText: 'Total number of units in project',
        ),
      );
      addSpacing();
      fields.add(_buildBoreyCompletionStatusField());
      addSpacing();
      fields.add(
        PropertyTextField(
          label: 'Starting Price',
          required: false,
          controller: _startingPriceController,
          hintText: 'Starting price in USD',
          infoText: 'Lowest available unit price',
        ),
      );
      addSpacing();
      fields.add(_buildTitleTypeField());
    } else if (_selectedPropertyType == 'Business for Sale') {
      fields.add(_buildLandSizeField(isLandType: true));
      addSpacing();
      fields.add(
        PropertyTextField(
          label: 'Monthly Rent',
          required: false,
          controller: _monthlyRentController,
          hintText: 'Enter monthly shop rent (USD)',
          infoText: 'Lower rent = higher profit potential',
        ),
      );
      addSpacing();
      fields.add(
        _buildDropdown(
          label: 'Listing Settings',
          required: true,
          value: _selectedListingSetting,
          items: ['Sale', 'Rent', 'To Let'],
          hasError: _hasAttemptedSubmit && _selectedListingSetting.isEmpty,
          focusKey: _listingSettingsKey,
          onChanged: (val) {
            if (val != null) setState(() => _selectedListingSetting = val);
          },
        ),
      );
      addSpacing();
      fields.add(_buildLeaseRemainingField());
      addSpacing();
      fields.add(
        PropertyTextField(
          label: 'Equipment Included',
          required: false,
          controller: _equipmentIncludedController,
          hintText:
              'List furniture, kitchen equipment, machines, POS system, etc.',
          infoText: 'Describe assets included in sale',
        ),
      );
      addSpacing();
      fields.add(
        PropertyTextField(
          label: 'Reason for Selling',
          required: false,
          controller: _reasonForSellingController,
          hintText: 'Example: Owner relocating abroad',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields,
    );
  }
}
