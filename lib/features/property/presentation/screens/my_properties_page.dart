import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'add_property_page.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';

import '../widgets/my_properties/property_card.dart';
import '../widgets/my_properties/empty_properties_state.dart';

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
          if (widget.isEmbedded && widget.onBackPressed != null)
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: widget.onBackPressed,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF1E293B),
                    size: 24,
                  ),
                ),
              ),
            ),
          Text(
            'My Properties',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
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
        children: [
          _buildTab(0, true),
          const SizedBox(width: 8),
          _buildTab(1, false),
          const SizedBox(width: 8),
          _buildTab(2, false),
          const SizedBox(width: 8),
          _buildTab(3, false),
        ],
      ),
    );
  }

  Widget _buildTab(int index, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getTabTitle(index),
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_properties.isEmpty) {
      return const EmptyPropertiesState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _properties.length,
      itemBuilder: (context, index) {
        final property = _properties[index];
        return PropertyCard(
          property: property,
          onOptionsTapped: () => _showPropertyOptions(context, property),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('assets/icons/home.svg', 'Home', false),
          _buildNavItem('assets/icons/chat.svg', 'Messages', false),
          const SizedBox(width: 48), // Space for FAB
          _buildNavItem(
            'assets/icons/heart.svg',
            'Favorites',
            false,
            hasBadge: true,
          ),
          _buildNavItem('assets/icons/user.svg', 'Profile', true),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    String iconPath,
    String label,
    bool isActive, {
    bool hasBadge = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SvgPicture.asset(
              iconPath,
              colorFilter: ColorFilter.mode(
                isActive ? const Color(0xFF5B5FEF) : const Color(0xFF9CA3AF),
                BlendMode.srcIn,
              ),
              width: 24,
              height: 24,
            ),
            if (hasBadge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF5B5FEF) : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  void _changePropertyStatus(String id, bool publish) {
    // In a real app, call a provider method here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          publish ? 'Property published' : 'Property moved to draft',
        ),
      ),
    );
  }

  void _deleteProperty(String id) {
    // In a real app, call a provider method here
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Property deleted')));
  }
}
