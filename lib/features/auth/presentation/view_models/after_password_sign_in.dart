import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Runs right after a successful email/phone and password sign-in, while
/// the sign-in page is still showing and the [password] is still in hand:
/// chat uses it to unlock the account's chat keys on this device.
typedef AfterPasswordSignIn =
    Future<void> Function(BuildContext context, String password);

/// Chat depends on sign-in, so sign-in does not import chat: the app
/// supplies this at start-up (see `lib/app/session`). Null (in tests, or
/// before it is wired) does nothing.
final afterPasswordSignInProvider = Provider<AfterPasswordSignIn?>(
  (ref) => null,
);
