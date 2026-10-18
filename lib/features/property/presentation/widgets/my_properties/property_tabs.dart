import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

class PropertyTabs extends StatelessWidget {
  final List<PropertyModel> properties;

  const PropertyTabs({super.key, required this.properties});

  String _getTabTitle(BuildContext context, int index) {
    final l10n = context.l10n;
    int count(String status) =>
        properties.where((p) => p.status == status).length;
    switch (index) {
      case 0:
        return l10n.propertyTabActive(count('Active'));
      case 1:
        return l10n.propertyTabPending(count('Pending'));
      case 2:
        return l10n.propertyTabDraft(count('Draft'));
      case 3:
        return l10n.propertyTabSold(count('Sold'));
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
          Expanded(child: _buildTab(context, 0, true)),
          const SizedBox(width: 8),
          Expanded(child: _buildTab(context, 1, false)),
          const SizedBox(width: 8),
          Expanded(child: _buildTab(context, 2, false)),
          const SizedBox(width: 8),
          Expanded(child: _buildTab(context, 3, false)),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? context.colors.textPrimary : context.colors.divider,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getTabTitle(context, index),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected
              ? context.colors.background
              : context.colors.textMuted,
        ),
      ),
    );
  }
}
