import 'package:flutter/services.dart';

/// The app's haptic vocabulary, named by what happened rather than by how
/// strong the tap is, following Apple's guidance: haptics confirm a choice
/// or an outcome, and are never added to every touch.
abstract final class AppHaptics {
  /// A value or tab was picked from a set of choices.
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Something small was done: a listing saved, a message sent.
  static Future<void> lightTap() => HapticFeedback.lightImpact();

  /// Something bigger began or snapped into place.
  static Future<void> firmTap() => HapticFeedback.mediumImpact();
}
