import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tilomnov/core/media/image_compressor.dart';
import 'package:tilomnov/core/media/image_upload_policy.dart';
import 'package:tilomnov/features/advertisements/presentation/advertisements_provider.dart';
import 'package:tilomnov/features/advertisements/presentation/advertisement_banner.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';

class AdminAdvertisementsPage extends ConsumerStatefulWidget {
  const AdminAdvertisementsPage({super.key});
  @override
  ConsumerState<AdminAdvertisementsPage> createState() =>
      _AdminAdvertisementsPageState();
}

class _AdminAdvertisementsPageState
    extends ConsumerState<AdminAdvertisementsPage> {
  bool _busy = false;
  String? _progress;
  void _refresh() {
    ref.invalidate(adminAdvertisementsProvider);
    ref.invalidate(activeAdvertisementsProvider);
  }

  Future<void> _upload() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final photos = await ImagePicker().pickMultiImage();
      for (var index = 0; index < photos.length; index++) {
        if (!mounted) return;
        setState(
          () => _progress = 'Uploading ${index + 1} of ${photos.length}',
        );
        final photo = await ImageCompressor.native.compress(
          photos[index],
          ImageUploadPolicy.propertyPhoto,
        );
        await ref.read(advertisementsRepositoryProvider).upload(photo);
      }
      if (photos.isNotEmpty && mounted) {
        AppPopup.showSuccess(context, 'Advertisement photos uploaded');
      }
    } catch (_) {
      if (mounted) {
        AppPopup.showError(
          context,
          'Could not upload all photos. Photos already uploaded have been kept.',
        );
      }
    } finally {
      if (mounted) {
        _refresh();
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
  }

  Future<void> _remove(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove advertisement?'),
        content: const Text(
          'This photo will stop appearing throughout the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(advertisementsRepositoryProvider).remove(id);
      if (mounted) _refresh();
    } catch (_) {
      if (mounted) {
        AppPopup.showError(
          context,
          'Could not remove the advertisement. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ads = ref.watch(adminAdvertisementsProvider);
    return AppPageScaffold(
      title: 'Advertisements',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Photo banners in Saved, Feed and Listings near you',
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _upload,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add photos'),
                ),
              ],
            ),
          ),
          if (_progress != null)
            Padding(padding: const EdgeInsets.all(12), child: Text(_progress!)),
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: ads.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: _refresh,
                  child: const Text('Could not load ads. Try again'),
                ),
              ),
              data: (items) => RefreshIndicator(
                onRefresh: () async {
                  await ref
                      .refresh(adminAdvertisementsProvider.future)
                      .then((_) {}, onError: (Object _, StackTrace _) {});
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.photo_library_outlined, size: 48),
                            SizedBox(height: 16),
                            Text('No ads yet'),
                            SizedBox(height: 8),
                            Text(
                              'The app shows no ad spaces until you add photos.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    for (final ad in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AdvertisementBanner(advertisement: ad),
                            TextButton.icon(
                              onPressed: _busy ? null : () => _remove(ad.id),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remove photo'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
