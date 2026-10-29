import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/shared/widgets/layout/paused_while_hidden.dart';

final _count = StateProvider<int>((ref) => 0);

void main() {
  late int builds;
  late ValueNotifier<bool> shown;
  late ProviderContainer container;

  Future<void> pumpPage(WidgetTester tester) async {
    builds = 0;
    shown = ValueNotifier(true);
    container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: shown,
            builder: (_, isShown, child) =>
                TickerMode(enabled: isShown, child: child!),
            child: PausedWhileHidden(
              builder: (context, ref) {
                builds++;
                return Text('count ${ref.watch(_count)}');
              },
            ),
          ),
        ),
      ),
    );
  }

  void change() => container.read(_count.notifier).state++;

  testWidgets('rebuilds with each change while shown', (tester) async {
    await pumpPage(tester);
    change();
    await tester.pump();

    expect(builds, 2);
    expect(find.text('count 1'), findsOneWidget);
  });

  testWidgets('does not rebuild for changes while hidden', (tester) async {
    await pumpPage(tester);
    shown.value = false;
    await tester.pump();
    final buildsWhenHidden = builds;

    change();
    await tester.pump();
    change();
    await tester.pump();

    expect(builds, buildsWhenHidden);
    expect(find.text('count 0', skipOffstage: false), findsOneWidget);
  });

  testWidgets('shown again, builds once with the data as it is', (
    tester,
  ) async {
    await pumpPage(tester);
    shown.value = false;
    await tester.pump();
    change();
    change();
    await tester.pump();
    final buildsWhenHidden = builds;

    shown.value = true;
    await tester.pump();

    expect(builds, buildsWhenHidden + 1);
    expect(find.text('count 2'), findsOneWidget);
  });
}
