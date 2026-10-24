import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/safety/data/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(apiClientProvider));
});
