import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/core/network/connection_restored_provider.dart';
import 'package:tilomnov/core/network/load_failure.dart';
import 'package:tilomnov/features/auth/data/google_sign_in_service.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/profile/data/repositories/avatar_repository.dart';
import 'package:tilomnov/features/profile/data/repositories/user_repository.dart';
import 'package:tilomnov/features/profile/presentation/view_models/avatar_controller.dart';
import 'package:tilomnov/features/profile/presentation/view_models/profile_edit_controller.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(apiClientProvider));
});

/// The signed-in user's profile; null for a guest. Signing out turns it to
/// null at once, so no screen keeps showing the previous user, or the
/// owner's actions on their listings.
/// The signed-in user's profile; null for a guest. Without internet it is
/// the one kept from last time, read again once the internet is back.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  if (!ref.watch(isSignedInProvider)) return null;
  final repo = ref.watch(userRepositoryProvider);
  try {
    return await repo.getProfile();
  } catch (e) {
    if (!LoadFailure.of(e).isConnection) rethrow;
    final kept = await repo.keptProfile();
    if (kept == null) rethrow;
    ref.listen(connectionRestoredProvider, (_, _) => ref.invalidateSelf());
    return kept;
  }
});

final profileEditControllerProvider = Provider<ProfileEditController>((ref) {
  return ProfileEditController(
    ref.watch(userRepositoryProvider),
    onSaved: () => ref.invalidate(userProfileProvider),
  );
});

final avatarControllerProvider = Provider<AvatarController>((ref) {
  return AvatarController(
    AvatarRepository(ref.watch(apiClientProvider)),
    readGooglePhoto: ref.watch(googleSignInServiceProvider).profilePhoto,
    onChanged: () => ref.invalidate(userProfileProvider),
  );
});
