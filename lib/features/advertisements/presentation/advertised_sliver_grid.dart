import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'advertisements_provider.dart';
import 'advertisement_banner.dart';

class AdvertisedSliverGrid extends ConsumerWidget {
  final SliverGridDelegate gridDelegate;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int rotationOffset;
  const AdvertisedSliverGrid({
    super.key,
    required this.gridDelegate,
    required this.itemCount,
    required this.itemBuilder,
    this.rotationOffset = 0,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeAdvertisementsProvider);
    final ads = state.hasError ? null : state.valueOrNull;
    if (ads == null || ads.isEmpty) {
      return SliverGrid.builder(
        gridDelegate: gridDelegate,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      );
    }
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        // shortcut: only regular grid delegates are supported, handle custom layouts when one is introduced.
        final layout =
            gridDelegate.getLayout(constraints) as SliverGridRegularTileLayout;
        final allowCardAd =
            MediaQuery.sizeOf(context).shortestSide >= 600 &&
            layout.crossAxisCount >= 2;
        final chunk = max(4, layout.crossAxisCount * 2);
        final slivers = <Widget>[];
        var start = 0;
        var slot = 0;
        while (start < max(1, itemCount)) {
          final ad = ads[(slot + rotationOffset) % ads.length];
          final portraitCard =
              allowCardAd && ad.isPortrait && start < itemCount;
          final count = min(chunk - (portraitCard ? 1 : 0), itemCount - start);
          final showAd = slot == 0 || start + count < itemCount;
          final cardAd = showAd && portraitCard;
          final firstListing = start;
          final adSlot = slot;
          slivers.add(
            SliverGrid.builder(
              gridDelegate: gridDelegate,
              itemCount: count + (cardAd ? 1 : 0),
              itemBuilder: (context, index) {
                if (cardAd && index == 0) {
                  return AdvertisementBanner(
                    key: ValueKey('ad-$adSlot'),
                    advertisement: ad,
                    inGrid: true,
                  );
                }
                return itemBuilder(
                  context,
                  firstListing + index - (cardAd ? 1 : 0),
                );
              },
            ),
          );
          if (showAd && !cardAd) {
            slivers.add(
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: AdvertisementBanner(
                    key: ValueKey('ad-$adSlot'),
                    advertisement: ad,
                  ),
                ),
              ),
            );
          } else if (start + count < itemCount) {
            slivers.add(
              SliverToBoxAdapter(
                child: SizedBox(
                  height: layout.mainAxisStride - layout.childMainAxisExtent,
                ),
              ),
            );
          }
          start += count;
          slot++;
          if (count == 0) break;
        }
        return SliverMainAxisGroup(slivers: slivers);
      },
    );
  }
}
