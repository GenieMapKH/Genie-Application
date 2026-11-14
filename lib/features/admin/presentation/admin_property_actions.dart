import 'admin_account_actions.dart';
import 'package:tilomnov/features/home/presentation/providers/property_carousel_provider.dart';
import 'package:tilomnov/features/closest_listings/presentation/view_models/closest_listings_provider.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_area_controller.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_nearby.dart';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/data/repositories/property_repository.dart';
import 'package:tilomnov/features/property/presentation/screens/add_property/add_property_page.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'admin_dashboard_provider.dart';
import 'admin_records_provider.dart';
import 'admin_moderation_provider.dart';
import 'admin_moderation_dialog.dart';

class AdminPropertyActions extends ConsumerStatefulWidget {
  final PropertyModel property;
  final VoidCallback onChanged;
  const AdminPropertyActions({
    super.key,
    required this.property,
    required this.onChanged,
  });
  @override
  ConsumerState<AdminPropertyActions> createState() =>
      _AdminPropertyActionsState();
}

class _AdminPropertyActionsState extends ConsumerState<AdminPropertyActions> {
  bool _busy = false;
  void _changed() {
    ref.invalidate(publicPropertiesProvider);
    ref.invalidate(closestListingsProvider);
    ref.read(propertyCarouselProvider.notifier).clear();
    ref.read(searchAreaControllerProvider.notifier).retry();
    ref.invalidate(adminDashboardProvider);
    ref.invalidate(adminRecordsProvider);
    ref.invalidate(adminReportsProvider);
    widget.onChanged();
  }

  Future<void> _edit() async {
    setState(() => _busy = true);
    try {
      final full = await ref.read(
        propertyDetailProvider(widget.property.id).future,
      );
      if (!mounted) return;
      final property = await Navigator.of(context, rootNavigator: true)
          .push<PropertyModel>(
            MaterialPageRoute(
              builder: (_) => ProviderScope(
                overrides: [
                  propertyRepositoryProvider.overrideWith(
                    (ref) => PropertyRepository(
                      ref.watch(apiClientProvider),
                      admin: true,
                    ),
                  ),
                ],
                child: AddPropertyPage.edit(full),
              ),
            ),
          );
      if (property != null && mounted) _changed();
    } catch (_) {
      if (mounted) {
        AppPopup.showError(
          context,
          'Could not open the property editor. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    final reason = await confirmModeration(
      context,
      title: 'Remove post',
      message:
          'Remove this post from the platform? Its reports and payment records will be kept.',
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(adminModerationRepositoryProvider)
          .removeProperty(widget.property.id, reason);
      if (!mounted) return;
      AppPopup.showSuccess(context, 'Post removed');
      _changed();
    } catch (error) {
      if (mounted) {
        showFailure(
          context,
          error: error,
          fallback: 'Could not remove the post. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _busy || widget.property.status == 'Deleted'
                  ? null
                  : _edit,
              icon: const Icon(LucideIcons.pencil),
              label: const Text('Edit post'),
            ),
            OutlinedButton.icon(
              onPressed: _busy || widget.property.status == 'Deleted'
                  ? null
                  : _remove,
              icon: const Icon(LucideIcons.imageOff),
              label: const Text('Remove post'),
            ),
            if (widget.property.ownerId != null)
              AdminAccountActions(
                userId: widget.property.ownerId!,
                label: 'Owner actions',
                enabled: !_busy,
                onChanged: _changed,
              ),
            if (_busy)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    ),
  );
}
