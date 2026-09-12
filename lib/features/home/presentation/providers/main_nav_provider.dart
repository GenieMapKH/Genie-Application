import 'package:flutter_riverpod/flutter_riverpod.dart';

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
