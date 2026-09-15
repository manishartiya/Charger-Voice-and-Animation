import 'dart:ui' as ui;
import 'package:charge_voice/charging_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('charge_voice/control');
  final calls = <String>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return call.method == 'snapshot'
              ? {'level': 50, 'plugged': true}
              : null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  testWidgets('Upward swipe from bottom dismisses, other swipes do not', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: FullScreenCharging(style: ChargeStyle.neon)),
    );
    await tester.pump();
    final size = tester.getSize(find.byType(Scaffold));
    await tester.dragFrom(Offset(size.width / 2, 50), const Offset(0, 150));
    expect(calls, isNot(contains('closeAnimation')));
    await tester.dragFrom(
      Offset(size.width / 2, size.height - 40),
      const Offset(0, -200),
    );
    await tester.pump();
    expect(calls, contains('closeAnimation'));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Cached charging host accepts a fresh theme for the next connection',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: FullScreenCharging(style: ChargeStyle.neon)),
      );
      await tester.pump();
      ui.channelBuffers.push(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('showCharging', {
            'style': 'prism',
            'preview': false,
            'seconds': 10,
          }),
        ),
        (_) {},
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('PRISM BLOOM'), findsOneWidget);
      expect(find.text('CHARGER CONNECTED'), findsOneWidget);
      expect(find.text('NEON PULSE'), findsNothing);
      expect(calls, contains('animationReady'));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
