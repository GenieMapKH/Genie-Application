import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import '../data/advertisement.dart';
import '../data/advertisements_repository.dart';

final advertisementsRepositoryProvider = Provider(
  (ref) => AdvertisementsRepository(ref.watch(apiClientProvider)),
);
final activeAdvertisementsProvider =
    FutureProvider.autoDispose<List<Advertisement>>((ref) async {
      final timer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => ref.invalidateSelf(),
      );
      ref.onDispose(timer.cancel);
      final ads = await ref.watch(advertisementsRepositoryProvider).load();
      ads.shuffle(Random());
      return ads;
    });
final adminAdvertisementsProvider =
    FutureProvider.autoDispose<List<Advertisement>>(
      (ref) => ref.watch(advertisementsRepositoryProvider).load(admin: true),
    );

int adSlotCount(int listings) => listings > 4 ? (listings - 1) ~/ 4 : 1;
int? listingIndexAtAdSlot(int index, int listings) =>
    (listings <= 4 && index == listings) || index % 5 == 4
    ? null
    : index - index ~/ 5;
