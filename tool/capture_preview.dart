// Render the real Flutter widgets with sample battery data for visual review.
// flutter test tool/capture_preview.dart --dart-define=FLUTTER_SDK=D:/Softwares/flutter
import 'dart:io';
import 'dart:ui' as ui;
import 'package:charge_voice/main.dart';
import 'package:charge_voice/charging_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Render app previews with sample battery data', (tester) async {
    const sdk = String.fromEnvironment('FLUTTER_SDK');
    if (sdk.isEmpty) {
      throw StateError('Pass --dart-define=FLUTTER_SDK=your/flutter/path');
    }
    await tester.runAsync(() async {
      final font = FontLoader('Roboto');
      font.addFont(
        File(
          '$sdk/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
      await font.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    tester.view.physicalSize = const Size(430, 1050);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('charge_voice/control'),
          (call) async => call.method == 'snapshot'
              ? {
                  'level': 64,
                  'plugged': true,
                  'source': 'Wall charger',
                  'temperature': 29.4,
                  'energy': {
                    'remainingMs': 2520000,
                    'estimateSource': 'Android estimate',
                    'observedChange': 3,
                    'observedMinutes': 5,
                  },
                  'enabled': true,
                  'notifications': true,
                  'batteryExempt': true,
                  'history': [
                    {
                      'text': '60 percent charge done.',
                      'time': DateTime(
                        2026,
                        9,
                        12,
                        14,
                        32,
                      ).millisecondsSinceEpoch,
                    },
                    {
                      'text': '50 percent charge done.',
                      'time': DateTime(
                        2026,
                        9,
                        12,
                        14,
                        18,
                      ).millisecondsSinceEpoch,
                    },
                    {
                      'text': 'Charger connected. Battery is at 42 percent.',
                      'time': DateTime(
                        2026,
                        9,
                        12,
                        14,
                        5,
                      ).millisecondsSinceEpoch,
                    },
                  ],
                }
              : null,
        );
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: const ChargeVoiceApp()),
    );
    await tester.runAsync(() async {
      for (final style in ChargeStyle.values.where(
        (style) => style.hasArtwork,
      )) {
        await precacheImage(
          ResizeImage(
            AssetImage('assets/characters/${style.name}.png'),
            width: 1080,
          ),
          key.currentContext!,
        );
      }
    });
    await tester.pumpAndSettle();
    for (final page in [
      'Dashboard',
      'Voice',
      'Activity',
      'Effects',
      'Battery',
    ]) {
      if (page != 'Dashboard') {
        await tester.tap(find.text(page));
        if (page == 'Effects') {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 800));
        } else {
          await tester.pumpAndSettle();
        }
      }
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final picture = await boundary.toImage(pixelRatio: 2);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        await Directory('docs/previews').create(recursive: true);
        await File(
          'docs/previews/${page.toLowerCase()}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
    }
    for (final style in ChargeStyle.values) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark(),
            home: FullScreenCharging(
              key: ValueKey(style),
              style: style,
              preview: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final picture = await boundary.toImage(pixelRatio: 2);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'docs/previews/animation-${style.name}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
