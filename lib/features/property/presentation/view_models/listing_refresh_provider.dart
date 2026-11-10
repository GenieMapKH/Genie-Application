import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rechecks listings while foregrounded and on return from another app.
/// shortcut: changes arrive within 30 seconds online, use server events if instant updates are needed.
final listingRefreshProvider = StreamProvider.autoDispose<int>((ref) {
  final events = StreamController<int>();
  var revision = 0;
  void refresh() => events.add(++revision);
  final lifecycle = AppLifecycleListener(onResume: refresh);
  final timer = Timer.periodic(const Duration(seconds: 30), (_) {
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) refresh();
  });
  ref.onDispose(() {
    timer.cancel();
    lifecycle.dispose();
    events.close();
  });
  return events.stream;
});
