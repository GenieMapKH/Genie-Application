import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Who posted a listing, as far as the listing knows them.
class PropertyPublisher {
  final String userId;
  final String? name;
  final String? avatarUrl;

  const PropertyPublisher({required this.userId, this.name, this.avatarUrl});
}

/// Opens the publisher's profile from one of their listings.
typedef PropertyPublisherOpener =
    Future<void> Function(BuildContext context, PropertyPublisher publisher);

/// The profile page belongs to search, which itself opens listings, so the
/// listing does not import it: the app supplies this at start-up (see
/// `lib/app/navigation`). Null (in tests, or before it is wired) hides the
/// "View" button.
final propertyPublisherOpenerProvider = Provider<PropertyPublisherOpener?>(
  (ref) => null,
);
