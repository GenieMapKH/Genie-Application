import 'package:tilomnov/l10n/generated/app_localizations.dart';

/// The name the server falls back to for someone who set none. It is
/// English, so it is shown in the user's language instead.
const _serverFallbackName = 'Property Owner';

/// [name] as given, or "Property Owner" in the user's language when there
/// is none (or only the server's English stand-in).
String ownerDisplayName(AppLocalizations l10n, String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty || trimmed == _serverFallbackName) {
    return l10n.ownerFallbackName;
  }
  return trimmed;
}
