import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The bottom tabs, by their position in the bar.
abstract final class MainTab {
  static const explore = 0;
  static const feed = 1;
  static const saved = 2;
  static const chat = 3;
  static const myProperties = 4;
  static const user = 5;
}

class MainNavState {
  final int currentIndex;
  final int previousIndex;

  const MainNavState({this.currentIndex = 0, this.previousIndex = 0});

  MainNavState copyWith({int? currentIndex, int? previousIndex}) {
    return MainNavState(
      currentIndex: currentIndex ?? this.currentIndex,
      previousIndex: previousIndex ?? this.previousIndex,
    );
  }
}

class MainNavNotifier extends StateNotifier<MainNavState> {
  MainNavNotifier() : super(const MainNavState());

  void setIndex(int newIndex) {
    state = state.copyWith(
      previousIndex: state.currentIndex,
      currentIndex: newIndex,
    );
  }

  void goBack() {
    state = state.copyWith(
      currentIndex: state.previousIndex,
      previousIndex: state.currentIndex,
    );
  }

  void resetToHome() {
    state = state.copyWith(previousIndex: state.currentIndex, currentIndex: 0);
  }
}

final mainNavProvider = StateNotifierProvider<MainNavNotifier, MainNavState>((
  ref,
) {
  return MainNavNotifier();
});
