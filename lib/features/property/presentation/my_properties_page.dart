import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'add_property_page.dart';
import '../models/property_model.dart';
import '../data/property_providers.dart';

class MyPropertiesPage extends ConsumerStatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBackPressed;

  const MyPropertiesPage({
    super.key,
    this.isEmbedded = false,
    this.onBackPressed,
  });

  @override
  ConsumerState<MyPropertiesPage> createState() => _MyPropertiesPageState();
}

class _MyPropertiesPageState extends ConsumerState<MyPropertiesPage> {
  List<PropertyModel> _properties = [];

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Active (${_properties.where((p) => p.status == 'Active').toList().length})';
      case 1:
        return 'Pending (${_properties.where((p) => p.status == 'Pending').toList().length})';
      case 2:
        return 'Draft (${_properties.where((p) => p.status == 'Draft').toList().length})';
      case 3:
        return 'Sold (${_properties.where((p) => p.status == 'Sold').toList().length})';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 42), // Increased margin on top
            _buildHeader(),
            const SizedBox(height: 32), // Increased margin below
            Expanded(
              child: propertiesAsync.when(
                data: (properties) {
                  _properties = properties;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTabsRow(),
                      const SizedBox(height: 24),
                      Expanded(child: _buildBody()),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF5B5FEF)),
                ),
                error: (error, stack) => Center(
                  child: TextButton(
                    onPressed: () =>
                        ref.read(propertiesProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ),
              ),
            ),
          ],
        ),
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
                ref.read(propertiesProvider.notifier).refresh();
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                if (widget.onBackPressed != null) {
                  widget.onBackPressed!();
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
            ),
          ),
          Text(
            'My Properties',
            style: GoogleFonts.inter(
              color: const Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(4, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index < 3 ? 24.0 : 0),
            child: Text(
              _getTabTitle(index),
              style: GoogleFonts.inter(
                color: const Color(0xFF5B5FEF),
                fontSize: 15, // Increased font size
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    final activeProps = _properties.where((p) => p.status == 'Active').toList();
    final pendingProps = _properties
        .where((p) => p.status == 'Pending')
        .toList();
    final draftProps = _properties.where((p) => p.status == 'Draft').toList();
    final soldProps = _properties.where((p) => p.status == 'Sold').toList();

    final allEmpty =
        activeProps.isEmpty &&
        pendingProps.isEmpty &&
        draftProps.isEmpty &&
        soldProps.isEmpty;

    if (allEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: [
        if (activeProps.isNotEmpty) ...[
          _buildSectionHeader('All'),
          ...activeProps.map((p) => _buildPropertyCard(p)),
        ],
        if (pendingProps.isNotEmpty) ...[
          _buildSectionHeader('Pending'),
          ...pendingProps.map((p) => _buildPropertyCard(p)),
        ],
        if (draftProps.isNotEmpty) ...[
          _buildSectionHeader('Draft'),
          ...draftProps.map((p) => _buildPropertyCard(p)),
        ],
        if (soldProps.isNotEmpty) ...[
          _buildSectionHeader('Sold'),
          ...soldProps.map((p) => _buildPropertyCard(p)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }

  void _showPropertyOptions(BuildContext context, PropertyModel property) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final isDraft = property.status == 'Draft';
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (isDraft)
                ListTile(
                  leading: const Icon(Icons.public, color: Color(0xFF5B5FEF)),
                  title: const Text('Publish to Public'),
                  onTap: () {
                    Navigator.pop(context);
                    _changePropertyStatus(property.id, true);
                  },
                )
              else
                ListTile(
                  leading: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF5B5FEF),
                  ),
                  title: const Text('Move to Draft'),
                  onTap: () {
                    Navigator.pop(context);
                    _changePropertyStatus(property.id, false);
                  },
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFE5484D),
                ),
                title: const Text(
                  'Delete Property',
                  style: TextStyle(color: Color(0xFFE5484D)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProperty(property.id);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changePropertyStatus(String id, bool publish) async {
    try {
      if (publish) {
        await ref.read(propertyRepositoryProvider).publish(id);
      } else {
        await ref.read(propertyRepositoryProvider).unpublish(id);
      }
      ref.invalidate(propertiesProvider);
      ref.invalidate(publicPropertiesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status')));
      }
    }
  }

  Future<void> _deleteProperty(String id) async {
    try {
      await ref.read(propertyRepositoryProvider).remove(id);
      ref.invalidate(propertiesProvider);
      ref.invalidate(publicPropertiesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete property')));
      }
    }
  }

  Widget _buildPropertyCard(PropertyModel property) {
    Color statusBgColor;
    Color statusTextColor;
    switch (property.status) {
      case 'Active':
        statusBgColor = const Color(0xFFD1FAE5);
        statusTextColor = const Color(0xFF059669);
        break;
      case 'Pending':
        statusBgColor = const Color(0xFFFEF3C7);
        statusTextColor = const Color(0xFFD97706);
        break;
      case 'Sold':
        statusBgColor = const Color(0xFFFEE2E2);
        statusTextColor = const Color(0xFFDC2626);
        break;
      case 'Draft':
      default:
        statusBgColor = const Color(0xFFF3F4F6);
        statusTextColor = const Color(0xFF6B7280);
        break;
    }

    return GestureDetector(
      onLongPress: () => _showPropertyOptions(context, property),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
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
            // Image Area
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: Color(0xFFF3F4F6),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: property.imageUrls.isNotEmpty
                      ? Image.network(
                          property.imageUrls.first,
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
                // Property Type Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          property.propertyType == 'Land'
                              ? Icons.landscape
                              : Icons.home_outlined,
                          size: 14,
                          color: const Color(0xFF4B5563),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          property.propertyType,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Favorite Icon
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                // Dots indicator
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: i == 0 ? 12 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == 0
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            // Details Area
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$ ${property.price}',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          property.status,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    property.propertyType == 'Land'
                        ? '1670 m² | Land for sale'
                        : '4 bds | 5 ba | 115.5 m² | ${property.propertyType} for sale',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    property.title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Edit',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB), // Blue color
                    ),
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem('5', 'Contacts'),
                        const SizedBox(width: 12),
                        _buildStatItem('1,688', 'Views'),
                        const SizedBox(width: 12),
                        _buildStatItem('99', 'Saves'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Row(
      children: [
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 64.0,
          ), // Fixed vertical padding
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB), // Very light gray
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Don't expand to full height
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
