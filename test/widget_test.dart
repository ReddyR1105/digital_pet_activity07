import 'package:digital_pet/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tap(WidgetTester tester, String label, [int times = 1]) async {
  for (var i = 0; i < times; i++) {
    await tester.tap(find.widgetWithText(ElevatedButton, label));
    await tester.pump();
  }
}

void meters(int happiness, int hunger) {
  expect(find.text('Happiness: $happiness'), findsOneWidget);
  expect(find.text('Hunger: $hunger'), findsOneWidget);
}

void careDisabled(WidgetTester tester) {
  for (final label in ['Feed', 'Play']) {
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, label),
    );
    expect(button.onPressed, isNull);
  }
}

Future<void> close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(minutes: 10));
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('Name confirmation and feeding use resulting hunger', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    meters(50, 50);
    await tester.enterText(find.byType(TextField), '  Luna  ');
    await tap(tester, 'Confirm Name');
    expect(find.text('Pet: Luna'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '   ');
    await tap(tester, 'Confirm Name');
    expect(find.text('Pet: Luna'), findsOneWidget);
    await tap(tester, 'Feed', 2);
    meters(70, 30);
    await tap(tester, 'Feed');
    meters(50, 20);
    await tap(tester, 'Feed', 6);
    meters(0, 0);
    await tap(tester, 'Play', 25);
    meters(100, 100);
    await close(tester);
  });

  testWidgets('Hunger reaches 100 safely, then loses happiness and ends game', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 29));
    meters(50, 50);
    await tester.pump(const Duration(seconds: 1));
    meters(50, 55);
    await tester.pump(const Duration(minutes: 4));
    meters(50, 95);
    await tester.pump(const Duration(seconds: 30));
    meters(50, 100);
    await tester.pump(const Duration(seconds: 30));
    meters(30, 100);
    await tester.pump(const Duration(seconds: 30));
    meters(10, 100);
    expect(find.text('GAME OVER'), findsOneWidget);
    careDisabled(tester);
    await tester.pump(const Duration(minutes: 5));
    meters(10, 100);
    await tap(tester, 'Reset');
    meters(50, 50);
    await tester.pump(const Duration(seconds: 30));
    meters(50, 55);
    await close(tester);
  });

  testWidgets('Exactly 80 does not win; high mood must last three minutes', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tap(tester, 'Play', 3);
    meters(80, 65);
    await tester.pump(const Duration(minutes: 3));
    expect(find.text('YOU WIN!'), findsNothing);
    await tap(tester, 'Reset');
    await tap(tester, 'Play', 4);
    meters(90, 70);
    await tester.pump(const Duration(seconds: 179));
    expect(find.text('YOU WIN!'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('YOU WIN!'), findsOneWidget);
    careDisabled(tester);
    final before = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .map((meter) => meter.value)
        .toList();
    await tester.pump(const Duration(minutes: 5));
    expect(
      tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .map((meter) => meter.value)
          .toList(),
      before,
    );
    await tap(tester, 'Reset');
    meters(50, 50);
    expect(find.text('Pet is active'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    meters(50, 55);
    await close(tester);
  });

  testWidgets('Dropping to 80 cancels win and recovery starts a full timer', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tap(tester, 'Play', 4);
    await tester.pump(const Duration(minutes: 1));
    await tap(tester, 'Feed', 6);
    meters(80, 20);
    await tester.pump(const Duration(minutes: 2));
    expect(find.text('YOU WIN!'), findsNothing);
    await tap(tester, 'Play');
    await tester.pump(const Duration(minutes: 1));
    await tap(tester, 'Play'); // Keeping mood high must not restart the timer.
    await tester.pump(const Duration(seconds: 119));
    expect(find.text('YOU WIN!'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('YOU WIN!'), findsOneWidget);
    await close(tester);
  });

  testWidgets(
    'Pause freezes care; resume starts fresh timers without duplicates',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tap(tester, 'Play', 4);
      await tester.pump(const Duration(minutes: 1));
      meters(90, 80);
      await tap(tester, 'Pause');
      expect(find.text('PAUSED'), findsOneWidget);
      careDisabled(tester);
      await tester.pump(const Duration(minutes: 5));
      meters(90, 80);
      await tap(tester, 'Resume');
      await tap(tester, 'Pause');
      await tap(tester, 'Resume');
      await tap(tester, 'Feed', 2);
      meters(100, 60);
      await tester.pump(const Duration(seconds: 30));
      meters(100, 65);
      await tester.pump(const Duration(seconds: 149));
      expect(find.text('YOU WIN!'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('YOU WIN!'), findsOneWidget);
      await close(tester);
    },
  );

  testWidgets(
    'Reset during play and pause cancels old timers and preserves name',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.enterText(find.byType(TextField), 'Luna');
      await tap(tester, 'Confirm Name');
      await tap(tester, 'Play', 4);
      await tester.pump(const Duration(seconds: 20));
      await tap(tester, 'Reset');
      await tester.pump(const Duration(seconds: 10));
      meters(50, 50);
      await tester.pump(const Duration(seconds: 20));
      meters(50, 55);
      await tap(tester, 'Pause');
      await tap(tester, 'Reset');
      meters(50, 50);
      expect(find.text('Pet: Luna'), findsOneWidget);
      expect(find.text('Pet is active'), findsOneWidget);
      await tester.pump(const Duration(minutes: 3));
      meters(50, 80);
      expect(find.text('YOU WIN!'), findsNothing);
      await close(tester);
    },
  );
}
