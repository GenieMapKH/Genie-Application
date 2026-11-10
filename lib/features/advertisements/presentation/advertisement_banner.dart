import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/media/app_network_image.dart';
import '../data/advertisement.dart';
import 'advertisements_provider.dart';

class AdvertisementSlot extends ConsumerWidget {
  final int rotationOffset;
  const AdvertisementSlot({super.key, this.rotationOffset = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeAdvertisementsProvider);
    final ads = state.hasError ? null : state.valueOrNull;
    if (ads == null || ads.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AdvertisementBanner(
        advertisement: ads[rotationOffset % ads.length],
      ),
    );
  }
}

class AdvertisementBanner extends StatelessWidget {
  final Advertisement advertisement;
  final bool inGrid;
  const AdvertisementBanner({
    super.key,
    required this.advertisement,
    this.inGrid = false,
  });
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.advertisementLabel,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: inGrid && advertisement.isPortrait ? 2 / 3 : 16 / 7,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: AppNetworkImage(
                  url: advertisement.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    child: Text(
                      context.l10n.advertisementLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
