import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'add_property_page.dart';
import '../models/property_model.dart';
import '../data/property_providers.dart';

part 'my_properties_page_widgets.dart';

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
    final pendingProps = _properties.where((p) => p.status == 'Pending').toList();
    final draftProps = _properties.where((p) => p.status == 'Draft').toList();
    final soldProps = _properties.where((p) => p.status == 'Sold').toList();

    final List<dynamic> items = [];
    if (activeProps.isNotEmpty) {
      items.add('All');
      items.addAll(activeProps);
    }
    if (pendingProps.isNotEmpty) {
      items.add('Pending');
      items.addAll(pendingProps);
    }
    if (draftProps.isNotEmpty) {
      items.add('Draft');
      items.addAll(draftProps);
    }
    if (soldProps.isNotEmpty) {
      items.add('Sold');
      items.addAll(soldProps);
    }

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is String) {
          return _buildSectionHeader(item);
        } else if (item is PropertyModel) {
          return _buildPropertyCard(item);
        }
        return const SizedBox.shrink();
      },
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
