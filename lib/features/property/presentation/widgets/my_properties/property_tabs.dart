import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/property/data/models/property_model.dart';

class PropertyTabs extends StatelessWidget {
  final List<PropertyModel> properties;

  const PropertyTabs({super.key, required this.properties});

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Active (${properties.where((p) => p.status == 'Active').length})';
      case 1:
        return 'Pending (${properties.where((p) => p.status == 'Pending').length})';
      case 2:
        return 'Draft (${properties.where((p) => p.status == 'Draft').length})';
      case 3:
        return 'Sold (${properties.where((p) => p.status == 'Sold').length})';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(child: _buildTab(0, true)),
          const SizedBox(width: 8),
          Expanded(child: _buildTab(1, false)),
          const SizedBox(width: 8),
          Expanded(child: _buildTab(2, false)),
          const SizedBox(width: 8),
          Expanded(child: _buildTab(3, false)),
        ],
      ),
    );
  }

  Widget _buildTab(int index, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getTabTitle(index),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF6B7280),
        ),
      ),
    );
  }
}
