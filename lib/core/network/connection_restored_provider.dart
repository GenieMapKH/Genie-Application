import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/network/network_status.dart';

/// Goes up by one each time the internet comes back after an outage
/// ([NetworkStatus]). Screens showing what they kept from before listen to
/// it to read their data again.
final connectionRestoredProvider =
    NotifierProvider<ConnectionRestoredNotifier, int>(
      ConnectionRestoredNotifier.new,
    );

class ConnectionRestoredNotifier extends Notifier<int> {
  @override
  int build() {
    final connection = NetworkStatus.instance.connection;
    var wasOffline = connection.value == ConnectionQuality.offline;
    void follow() {
      final offline = connection.value == ConnectionQuality.offline;
      if (wasOffline && !offline) state++;
      wasOffline = offline;
    }

    connection.addListener(follow);
    ref.onDispose(() => connection.removeListener(follow));
    return 0;
  }
}
