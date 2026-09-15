import 'package:charge_voice/port_glow.dart';
import 'package:charge_voice/preferences_panels.dart';
import 'package:charge_voice/charging_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Glow selections update preview and survive a new charging screen',
    (tester) async {
      final saved = <String, dynamic>{};
      const channel = MethodChannel('charge_voice/control');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async =>
                call.method == 'snapshot' ? {'level': 64, ...saved} : null,
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (_, update) => SingleChildScrollView(
                child: EffectPreferences(
                  data: saved,
                  onSetting: (value) => update(() => saved.addAll(value)),
                ),
              ),
            ),
          ),
        ),
      );
      Future<void> choose(String label) async {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }

      await choose('Right');
      await choose('Lightning');
      await choose('Rainbow');
      await choose('Fine-tune your glow');
      await choose('Wide');
      await choose('Soft');
      await choose('Fast');
      await choose('End');
      final preview = tester.widget<PortGlow>(find.byType(PortGlow));
      expect(preview.options.style, 'lightning');
      expect(preview.options.color, 'rainbow');
      expect(preview.options.size, 1.4);
      expect(preview.options.intensity, .4);
      expect(preview.options.speed, 1.5);
      expect(preview.options.offset, .75);
      expect(preview.position, 'right');
      await tester.pumpWidget(
        const MaterialApp(home: FullScreenCharging(style: ChargeStyle.neon)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final actual = tester.widget<PortGlow>(find.byType(PortGlow));
      expect(actual.options.style, preview.options.style);
      expect(actual.options.color, preview.options.color);
      expect(actual.options.size, preview.options.size);
      expect(actual.options.intensity, preview.options.intensity);
      expect(actual.options.speed, preview.options.speed);
      expect(actual.options.offset, preview.options.offset);
      expect(actual.position, preview.position);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Every port style paints on every edge and respects reduced motion',
    (tester) async {
      for (final style in portStyles.keys) {
        for (final edge in ['bottom', 'top', 'left', 'right']) {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: SizedBox(
                  width: 320,
                  height: 180,
                  child: PortGlow(
                    position: edge,
                    themeColor: Colors.cyan,
                    options: PortGlowOptions(
                      style: style,
                      size: 1.4,
                      offset: .75,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.hasRunningAnimations, false);
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets('Disabling port glow hides its controls and actual effect', (
    tester,
  ) async {
    const channel = MethodChannel('charge_voice/control');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async =>
              call.method == 'snapshot' ? {'portGlow': false} : null,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EffectPreferences(
            data: const {'portGlow': false},
            onSetting: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(PortGlow), findsNothing);
    expect(find.text('Glow style'), findsNothing);
    await tester.pumpWidget(
      const MaterialApp(home: FullScreenCharging(style: ChargeStyle.neon)),
    );
    await tester.pump();
    expect(find.byType(PortGlow), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
