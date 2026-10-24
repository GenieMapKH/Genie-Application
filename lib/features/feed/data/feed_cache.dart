import 'package:shared_preferences/shared_preferences.dart';

/// The first page of the feed as last read, kept on this device so the Feed
/// tab shows it at once on the next start while the new one loads. Kept per
/// account: someone else signing in on the same phone never sees it.
class FeedCache {
  static String _key(String userId) => 'feed.first_page.v1.$userId';

  /// The page's JSON as the server sent it, or null when none is kept.
  Future<String?> read(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_key(userId));
  }

  Future<void> write(String userId, String json) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key(userId), json);
  }
}
