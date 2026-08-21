import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/core/services/auth_service.dart';
import '../models/property_model.dart';
import 'property_repository.dart';

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository(ref.watch(apiClientProvider));
});

final propertiesProvider = FutureProvider.autoDispose<List<PropertyModel>>((
  ref,
) async {
  final repo = ref.watch(propertyRepositoryProvider);
  return repo.fetchAll(forceRefresh: true);
});
