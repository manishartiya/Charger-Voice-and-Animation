import 'dart:io';
import 'dart:ui' as ui;
import 'package:charge_voice/port_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Render six port-glow styles', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('Roboto')
        ..addFont(
          File(
            'D:/Softwares/flutter/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
          ).readAsBytes().then(ByteData.sublistView),
        );
      await loader.load();
    });
    tester.view.physicalSize = const Size(720, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
          home: Scaffold(
            backgroundColor: const Color(0xFF100E1C),
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PORT GLOW STUDIO',
                    style: TextStyle(fontSize: 28, letterSpacing: 2),
                  ),
                  const Text(
                    'Six ways to light up your charging socket',
                    style: TextStyle(color: Color(0xFFABA4BF)),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        for (final entry in portStyles.entries)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: ColoredBox(
                              color: const Color(0xFF211D35),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Positioned(
                                    top: 20,
                                    left: 20,
                                    child: Text(
                                      entry.value,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  PortGlow(
                                    themeColor: const Color(0xFFB8A4FF),
                                    options: PortGlowOptions(
                                      style: entry.key,
                                      intensity: 1,
                                      size: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 850));
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'docs/previews/port-glow-styles.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox());
  });
}
