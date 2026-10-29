import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/search/data/models/publisher_summary.dart';

/// A person's or agency's public profile: who they are, and what they list.
class PublisherProfile {
  final PublisherSummary person;

  /// Published listings, newest first.
  final List<PropertyModel> properties;

  const PublisherProfile({required this.person, required this.properties});
}
