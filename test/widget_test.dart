import 'package:charge_voice/main.dart';
import 'package:charge_voice/charging_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('charge_voice/control');
  final calls = <String>[];
  bool enabled = false;
  var animationStyle = 'neon';
  var repeatFull = true;
  setUp(() {
    calls.clear();
    enabled = false;
    animationStyle = 'neon';
    repeatFull = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'setEnabled') {
            enabled = (call.arguments as Map)['enabled'] as bool;
          }
          if (call.method == 'settings') {
            final args = call.arguments as Map;
            if (args['animationStyle'] != null) {
              animationStyle = args['animationStyle'] as String;
            }
            if (args['repeatFull'] != null) {
              repeatFull = args['repeatFull'] as bool;
            }
          }
          if (call.method == 'snapshot') {
            return <String, dynamic>{
              'level': 49,
              'plugged': true,
              'source': 'USB',
              'temperature': 28.5,
              'enabled': enabled,
              'notifications': true,
              'batteryExempt': true,
              'history': <dynamic>[],
              'animationStyle': animationStyle,
              'repeatFull': repeatFull,
            };
          }
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  testWidgets(
    'Dashboard renders real platform battery values and enables monitoring',
    (tester) async {
      await tester.pumpWidget(const ChargeVoiceApp());
      await tester.pumpAndSettle();
      expect(find.text('USB'), findsOneWidget);
      expect(find.text('28.5°C'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Battery 49 percent',
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byType(Switch),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(calls, contains('setEnabled'));
      expect(enabled, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'Voice preview invokes Android speech and navigation shows empty activity',
    (tester) async {
      await tester.pumpWidget(const ChargeVoiceApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voice'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Test my voice'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Test my voice'));
      await tester.pumpAndSettle();
      expect(calls, contains('testVoice'));
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(find.text('Your next charge starts the story.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('Narrow phone has no layout overflow on any page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ChargeVoiceApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Voice'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Effects'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Animation styles persist through Android and preview opens selected style',
    (tester) async {
      await tester.pumpWidget(const ChargeVoiceApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Effects'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('style-aurora')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const ValueKey('style-aurora'))),
        alignment: .5,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const ValueKey('style-aurora')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(animationStyle, 'aurora');
      await tester.scrollUntilVisible(
        find.text('Full-screen preview'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Full-screen preview'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(calls, contains('previewAnimation'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('Full-charge repeating voice can be disabled', (tester) async {
    await tester.pumpWidget(const ChargeVoiceApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voice'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('100% charge reminder'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('100% charge reminder')),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('100% charge reminder'));
    await tester.pumpAndSettle();
    expect(repeatFull, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('All seventeen scenes render without close buttons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final style in ChargeStyle.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: FullScreenCharging(
            key: ValueKey(style),
            style: style,
            preview: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, contains('animationReady'));
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Close animation'), findsNothing);
      expect(find.text('Dismiss animation'), findsNothing);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'Sleep-mode setup exposes missing permission and phone settings',
    (tester) async {
      await tester.pumpWidget(const ChargeVoiceApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Effects'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.scrollUntilVisible(
        find.text('Phone permissions'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('Phone permissions')),
        alignment: .5,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Phone permissions'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(calls, contains('phonePermissions'));
      expect(find.text('Last result: Not tested yet'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
