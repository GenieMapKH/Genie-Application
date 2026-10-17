import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/screens/add_property_page.dart';
import 'package:genie/features/property/presentation/view_models/property_nearby.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import 'package:genie/features/property/presentation/view_models/property_visibility.dart';
import 'package:genie/features/property/presentation/widgets/detail/property_contact_bar.dart';
import 'package:genie/features/property/presentation/widgets/detail/property_visibility_sheet.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/app_popup.dart';

/// Takes the place of Chat / Call Now when the owner opens their own
/// listing: Edit opens the edit form, Visibility makes it public, a draft
/// or sold.
class PropertyOwnerActions extends ConsumerStatefulWidget {
  final PropertyModel property;

  /// Called after the listing was edited: what the sheet shows is outdated.
  final VoidCallback onEdited;

  const PropertyOwnerActions({
    super.key,
    required this.property,
    required this.onEdited,
  });

  @override
  ConsumerState<PropertyOwnerActions> createState() =>
      _PropertyOwnerActionsState();
}

class _PropertyOwnerActionsState extends ConsumerState<PropertyOwnerActions> {
  /// Follows visibility changes made here.
  late String _status = widget.property.status;
  bool _busy = false;

  Future<void> _edit() async {
    setState(() => _busy = true);
    try {
      // The sheet may hold the map's slim copy; the form needs every detail.
      final full = await ref.read(
        propertyDetailProvider(widget.property.id).future,
      );
      if (!mounted) return;
      final saved = await Navigator.of(context, rootNavigator: true)
          .push<PropertyModel>(
            MaterialPageRoute(builder: (_) => AddPropertyPage.edit(full)),
          );
      if (saved == null) return;
      ref.invalidate(propertyDetailProvider(widget.property.id));
      await ref.read(propertiesProvider.notifier).refreshQuietly();
      widget.onEdited();
    } catch (e, stack) {
      AppLogger.error('Opening the listing editor failed', e, stack);
      if (mounted) {
        AppPopup.showError(context, context.l10n.propertyCouldNotOpenEditor);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeVisibility() async {
    final target = await PropertyVisibilitySheet.show(context, _status);
    if (target == null || !mounted) return;
    if (visibilityChange(_status, target) == null) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(propertiesProvider.notifier)
          .changeVisibility(widget.property.id, _status, target);
      if (!mounted) return;
      setState(() => _status = _statusOf(target));
      AppPopup.showSuccess(context, context.l10n.propertyVisibilityChanged);
    } catch (e, stack) {
      AppLogger.error('Changing listing visibility failed', e, stack);
      if (mounted) {
        AppPopup.showError(
          context,
          context.l10n.propertyCouldNotChangeVisibility,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _statusOf(PropertyVisibility visibility) =>
      switch (visibility) {
        PropertyVisibility.public => 'Active',
        PropertyVisibility.draft => 'Draft',
        PropertyVisibility.sold => 'Sold',
      };

  String _visibilityLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (PropertyVisibility.of(_status)) {
      PropertyVisibility.public => l10n.propertyVisibilityPublic,
      PropertyVisibility.draft => l10n.propertyVisibilityDraft,
      PropertyVisibility.sold => l10n.propertyVisibilitySold,
      null => l10n.propertyVisibility,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: SizedBox(
        height: PropertyContactBar.height - 24,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _edit,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: context.colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: context.colors.textPrimary,
                ),
                label: Text(
                  context.l10n.propertyEdit,
                  style: textStyle.copyWith(color: context.colors.textPrimary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _changeVisibility,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: context.colors.accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(
                  Icons.visibility_outlined,
                  size: 18,
                  color: context.colors.onPrimary,
                ),
                label: Text(
                  _visibilityLabel(context),
                  style: textStyle.copyWith(color: context.colors.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
