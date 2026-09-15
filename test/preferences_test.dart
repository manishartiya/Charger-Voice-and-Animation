import 'package:charge_voice/preferences_panels.dart';
import 'package:charge_voice/charging_animation.dart';
import 'package:charge_voice/cinematic_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('charge_voice/control');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'languages') {
            return [
              {'tag': 'en-US', 'name': 'English', 'translated': true},
              {'tag': 'ja-JP', 'name': 'Japanese / 日本語', 'translated': true},
            ];
          }
          if (call.method == 'snapshot') return {'level': 64, 'portGlow': true};
          return true;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  Widget host(Widget child) => MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
  testWidgets('All duration choices and port edges reach settings', (
    tester,
  ) async {
    final settings = <Map<String, dynamic>>[];
    await tester.pumpWidget(
      host(EffectPreferences(data: const {}, onSetting: settings.add)),
    );
    for (final seconds in [5, 10, 15, 20]) {
      await tester.tap(find.text('$seconds sec'));
      expect(settings.last, {'animationSeconds': seconds});
    }
    await tester.tap(find.text('Top'));
    expect(settings.last, {'portPosition': 'top'});
    await tester.tap(find.byType(Switch));
    expect(settings.last, {'portGlow': false});
  });
  testWidgets('Search Japanese and save the actual speech locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(VoiceLanguagePanel(data: const {}, onChanged: () async {})),
    );
    await tester.tap(find.text('Choose language'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Japanese');
    await tester.pumpAndSettle();
    expect(find.text('English'), findsNothing);
    await tester.tap(find.text('Japanese / 日本語'));
    await tester.pumpAndSettle();
    expect(calls.last.method, 'settings');
    expect(calls.last.arguments, {'voiceLanguage': 'ja-JP'});
  });
  testWidgets(
    'Sounds target chosen percentage and persist its duration independently',
    (tester) async {
      await tester.pumpWidget(
        host(
          SoundAssignments(
            data: const {
              'sounds': {
                '50': {'name': 'My sound.wav', 'custom': true, 'seconds': 5},
              },
            },
            onChanged: () async {},
          ),
        ),
      );
      await tester.tap(find.text('50%'));
      await tester.pumpAndSettle();
      expect(find.text('My sound.wav'), findsOneWidget);
      await tester.tap(find.text('10 s'));
      await tester.pumpAndSettle();
      expect(calls.last.method, 'soundSettings');
      expect(calls.last.arguments, {'slot': '50', 'seconds': 10});
      await tester.tap(find.byTooltip('Preview selected sound'));
      await tester.pumpAndSettle();
      expect(calls.last.arguments, {'slot': '50'});
      await tester.tap(find.text('Use built-in voice'));
      await tester.pumpAndSettle();
      expect(calls.last.method, 'removeSound');
      expect(calls.last.arguments, {'slot': '50'});
    },
  );
  testWidgets(
    'Cinematic screen uses character asset and selected close duration',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FullScreenCharging(style: ChargeStyle.water, seconds: 5),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ChargingLightBar), findsOneWidget);
      expect(find.text('Dismiss animation'), findsNothing);
      expect(find.byType(CinematicScene), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image is ResizeImage
          ? (image.image as ResizeImage).imageProvider
          : image.image;
      expect((provider as AssetImage).assetName, 'assets/characters/water.png');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
