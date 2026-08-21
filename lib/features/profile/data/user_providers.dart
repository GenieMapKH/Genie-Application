import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/core/services/auth_service.dart';
import 'user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(apiClientProvider));
});

final userProfileProvider = FutureProvider.autoDispose<UserProfile>((
  ref,
) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getProfile();
});
