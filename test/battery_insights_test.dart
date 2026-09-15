import 'package:charge_voice/battery_insights.dart';
import 'package:charge_voice/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Remaining duration formats hours, minutes and unavailable values', () {
    expect(formatRemaining(null), 'Learning…');
    expect(formatRemaining(-1), 'Learning…');
    expect(formatRemaining(60000), '1 min');
    expect(formatRemaining(3660000), '1 hr 1 min');
    expect(formatRemaining(7200000), '2 hr');
  });
  testWidgets(
    'Battery usage opens actual system report and forecast switch saves',
    (tester) async {
      final calls = <String>[];
      final arguments = <Map<String, dynamic>?>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BatteryInsights(
                data: const {
                  'plugged': false,
                  'energy': {'remainingMs': 3660000},
                },
                onAction: (method, [args]) async {
                  calls.add(method);
                  arguments.add(args);
                },
              ),
            ),
          ),
        ),
      );
      expect(find.text('1 hr 1 min'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      expect(calls.last, 'settings');
      expect(arguments.last, {'showTimeEstimate': false});
      await tester.scrollUntilVisible(find.text('View app battery usage'), 150);
      await tester.ensureVisible(find.text('View app battery usage'));
      await tester.tap(find.text('View app battery usage'));
      expect(calls.last, 'batteryUsage');
    },
  );
  testWidgets('Rapid tab changes animate without reusing scroll controllers', (
    tester,
  ) async {
    const channel = MethodChannel('charge_voice/control');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'snapshot'
              ? {'level': 50, 'plugged': false}
              : null,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await tester.pumpWidget(const ChargeVoiceApp());
    await tester.pumpAndSettle();
    for (final tab in ['Voice', 'Dashboard', 'Battery', 'Effects', 'Voice']) {
      await tester.tap(find.text(tab));
      await tester.pump(const Duration(milliseconds: 70));
      expect(tester.takeException(), isNull);
    }
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(AnimatedSwitcher), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
