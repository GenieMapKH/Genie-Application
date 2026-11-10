import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/admin/data/admin_dashboard_repository.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/admin/data/admin_service_health.dart';
import '../data/admin_rotation_status.dart';

final adminRotationProvider = FutureProvider.autoDispose<AdminRotationStatus>(
  (ref) => ref.watch(adminDashboardRepositoryProvider).rotations(),
);

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>(
  (ref) => AdminDashboardRepository(ref.watch(apiClientProvider)),
);

final adminSystemHealthProvider = FutureProvider.autoDispose<AdminSystemHealth>(
  (ref) => ref.watch(adminDashboardRepositoryProvider).health(),
);

final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardData>((
  ref,
) {
  return ref.watch(adminDashboardRepositoryProvider).load();
});
