import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/auth/data/google_sign_in_service.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/data/repositories/avatar_repository.dart';
import 'package:genie/features/profile/data/repositories/user_repository.dart';
import 'package:genie/features/profile/presentation/view_models/avatar_controller.dart';
import 'package:genie/features/profile/presentation/view_models/profile_edit_controller.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(apiClientProvider));
});

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getProfile();
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
