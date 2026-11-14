import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/core/network/api_cache_manager.dart';

/// Captured before I/O, never inferred from whoever is signed in when it ends.
typedef KeptCopyScope = ({String? owner, int generation});

/// Session-only API copies. Profiles, messages, keys and drafts never belong
/// in ordinary preferences. Restarting the app requires a fresh read.
class KeptCopyStore {
  final Future<String?> Function() account;
  const KeptCopyStore({required this.account});

  static final _copies = <String, String>{};
  static void clearSessionCopies() => _copies.clear();
  static int _generation = -1;
  static const _legacyPrefixes = [
    'profile.v1.',
    'chat.conversations.first_page.v1.',
    'own_listings.first_page.v1.',
    'saved.first_page.v1.',
    'feed.first_page.v1.',
    'closest.first_page.v1.',
  ];

  /// Removes old API copies only, not settings or unrelated preferences.
  static Future<void> purgeLegacyCopies() async {
    final preferences = await SharedPreferences.getInstance();
    for (final key in preferences.getKeys().toList()) {
      if (_legacyPrefixes.any(key.startsWith)) await preferences.remove(key);
    }
  }

  Future<KeptCopyScope> capture() async {
    final generation = ApiCacheManager().generation;
    String? owner;
    try {
      owner = await account();
    } catch (e) {
      AppLogger.error('The session copy owner could not be read', e);
    }
    return (owner: owner, generation: generation);
  }

  Future<bool> _isCurrent(KeptCopyScope scope) async {
    if (scope.generation != ApiCacheManager().generation) return false;
    try {
      final owner = await account();
      return scope.generation == ApiCacheManager().generation &&
          scope.owner == owner;
    } catch (_) {
      return scope.generation == ApiCacheManager().generation &&
          scope.owner == null;
    }
  }

  /// Prevents an old response being returned or cached for a new session.
  Future<void> requireCurrent(KeptCopyScope scope) async {
    if (!await _isCurrent(scope)) throw StateError('Session changed');
  }

  static void _discardOldSession() {
    final current = ApiCacheManager().generation;
    if (_generation == current) return;
    _copies.clear();
    _generation = current;
  }

  Future<T?> read<T>(
    String name, {
    required FutureOr<T> Function(Map<String, dynamic> json) parse,
  }) async {
    try {
      await purgeLegacyCopies();
      final scope = await capture();
      _discardOldSession();
      if (scope.owner == null) return null;
      final json = _copies['$name.${scope.owner}'];
      if (json == null) return null;
      final result = await parse(jsonDecode(json) as Map<String, dynamic>);
      return await _isCurrent(scope) ? result : null;
    } catch (e) {
      AppLogger.error('The session copy of $name could not be read', e);
      return null;
    }
  }

  Future<void> write(
    String name,
    Map<String, dynamic> json, {
    required KeptCopyScope scope,
  }) async {
    await requireCurrent(scope);
    await purgeLegacyCopies();
    await requireCurrent(scope);
    _discardOldSession();
    if (scope.owner == null) return;
    if (_copies.length >= 100) _copies.remove(_copies.keys.first);
    _copies['$name.${scope.owner}'] = jsonEncode(json);
  }
}
