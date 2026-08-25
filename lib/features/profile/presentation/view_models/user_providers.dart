import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/profile/data/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(apiClientProvider));
});

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getProfile();
});

