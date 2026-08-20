import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'add_property_page.dart';
import '../models/property_model.dart';
import '../data/property_repository.dart';

class MyPropertiesPage extends StatefulWidget {
  final bool isEmbedded;

  const MyPropertiesPage({super.key, this.isEmbedded = false});

  @override
  State<MyPropertiesPage> createState() => _MyPropertiesPageState();
}

class _MyPropertiesPageState extends State<MyPropertiesPage> {
  int _selectedTabIndex = 0;

  List<PropertyModel> get _propertiesForSelectedTab {
    switch (_selectedTabIndex) {
      case 0:
        return PropertyRepository.getPropertiesByStatus('Active');
      case 1:
        return PropertyRepository.getPropertiesByStatus('Pending');
      case 2:
        return PropertyRepository.getPropertiesByStatus('Draft');
      case 3:
        return PropertyRepository.getPropertiesByStatus('Sold');
      default:
        return [];
    }
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Active (${PropertyRepository.getPropertiesByStatus('Active').length})';
      case 1:
        return 'Pending (${PropertyRepository.getPropertiesByStatus('Pending').length})';
      case 2:
        return 'Draft (${PropertyRepository.getPropertiesByStatus('Draft').length})';
      case 3:
        return 'Sold (${PropertyRepository.getPropertiesByStatus('Sold').length})';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Text(
          'My Properties',
          style: GoogleFonts.inter(
            color: const Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabsRow(),
          const SizedBox(height: 24),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: widget.isEmbedded ? null : _buildBottomBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: widget.isEmbedded ? 20.0 : 70.0),
        child: SizedBox(
          width: 140,
          height: 44,
          child: ElevatedButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddPropertyPage(
                    boundaryPoints: [], // Empty for now or mock data
                    propertyArea: 0,
                  ),
                ),
              );
              if (mounted) {
                setState(() {}); // Rebuild to pick up newly added properties
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B5FEF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              elevation: 4,
            ),
            child: Text(
              'Add Property',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            child: Text(
              _getTabTitle(index),
              style: GoogleFonts.inter(
                color: isSelected
                    ? const Color(0xFF5B5FEF)
                    : const Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    final properties = _propertiesForSelectedTab;
    if (properties.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        return _buildPropertyCard(properties[index]);
      },
    );
  }

  Widget _buildPropertyCard(PropertyModel property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              color: Color(0xFFF3F4F6),
            ),
            clipBehavior: Clip.antiAlias,
            child: property.photos.isNotEmpty
                ? Image.file(
                    File(property.photos.first.path),
                    fit: BoxFit.cover,
                  )
                : const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Color(0xFF9CA3AF),
                      size: 48,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        property.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '\$${property.price}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5B5FEF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        property.propertyType,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF4B5563),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${property.createdAt.day}/${property.createdAt.month}/${property.createdAt.year}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB), // Very light gray
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Home icon with alert. Using a stack with Material icons as a fallback.
            Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.home_outlined,
                  size: 64,
                  color: Color(0xFFD1D5DB),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error,
                      size: 24,
                      color: Color(0xFFD1D5DB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'You haven\'t listed any\nproperty yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
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
          _buildNavItem(iconPath: 'assets/icons/explore.svg', label: 'Explore'),
          _buildNavItem(iconPath: 'assets/icons/saved.svg', label: 'Saved'),
          _buildNavItem(iconPath: 'assets/icons/chat.svg', label: 'Chat'),
          _buildNavItem(
            iconPath: 'assets/icons/property.svg',
            label: 'My Properties',
            isSelected: true,
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
    return GestureDetector(
      onTap: () {
        if (label == 'Explore') {
          Navigator.of(context).pop();
        }
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
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
