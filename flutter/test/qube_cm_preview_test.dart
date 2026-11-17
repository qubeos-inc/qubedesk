// Превью окна на компьютере, к которому подключились, и панели подключения.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/common/widgets/qube_glass.dart';
import 'package:flutter_hbb/common/widgets/qube_parts.dart';

Future<void> _font(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.view(File(f).readAsBytesSync().buffer)));
  }
  await l.load();
}

Widget _cm(Brightness b, {bool ask = false}) {
  final dark = b == Brightness.dark;
  final mut = (dark ? Colors.white : Colors.black).withOpacity(0.55);
  final perms = [
    (true, Icons.keyboard_alt_outlined, 'Клавиатура'),
    (true, Icons.content_paste_rounded, 'Буфер'),
    (true, Icons.volume_up_rounded, 'Звук'),
    (true, Icons.upload_file_rounded, 'Файлы'),
    (true, Icons.restart_alt_rounded, 'Перезапуск'),
    (false, Icons.videocam_rounded, 'Запись'),
    (false, Icons.block_rounded, 'Блок. ввода'),
    (false, Icons.visibility_off_rounded, 'Скрыть экран'),
  ];
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: b, fontFamily: 'Inter', useMaterial3: false),
    home: Material(
      color: Colors.transparent,
      child: QubeBackdrop(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QubeClientHeader(
                name: 'Эдуард Катрич · qubeOS',
                peerId: '69983058',
                status: ask ? 'Хочет подключиться к экрану' : 'Подключено · 01:01',
                live: !ask,
                onChat: ask ? null : () {},
              ),
              const SizedBox(height: 12),
              QubeGlass(
                radius: 20,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const QubeCardLabel(Icons.tune_rounded, 'Разрешения'),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.95,
                      children: [
                        for (final p in perms)
                          QubePermTile(enabled: p.$1, icon: p.$2, label: p.$3, tooltip: p.$3, onTap: () {}),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (ask) ...[
                Text('Пароль не нужен: доступ подтвердил сервер qubeOS',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: mut)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: QubeCmButton(text: 'Отклонить', onTap: () {})),
                  const SizedBox(width: 8),
                  Expanded(child: QubeCmButton(text: 'Принять', kind: QubeCmKind.primary, onTap: () {})),
                ]),
              ] else
                QubeCmButton(
                    text: 'Отключить', kind: QubeCmKind.danger,
                    icon: const Icon(Icons.link_off_rounded), onTap: () {}),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _bar() {
  Widget btn(IconData i, {Color bg = QubeBar.button, Color fg = Colors.white, String? text}) => Container(
        width: text == null ? QubeBar.size : null,
        height: QubeBar.size,
        padding: text == null ? null : const EdgeInsets.symmetric(horizontal: 10),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(QubeBar.radius)),
        child: Center(
          child: text == null
              ? Icon(i, size: 18, color: fg)
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(i, size: 10, color: qubeDanger),
                  const SizedBox(width: 5),
                  Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
        ),
      );
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Inter', useMaterial3: false),
    home: Material(
      color: const Color(0xFF3A3F4B),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: QubeBar.bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              btn(Icons.push_pin_outlined, bg: QubeBar.active),
              btn(Icons.bolt_rounded),
              btn(Icons.desktop_windows_outlined),
              btn(Icons.keyboard_alt_outlined),
              btn(Icons.chat_bubble_outline_rounded),
              btn(Icons.group_add_outlined, bg: qubePink.withOpacity(0.9)),
              const SizedBox(width: 8),
              btn(Icons.circle, text: 'REC'),
              btn(Icons.close_rounded, bg: QubeBar.close, fg: qubeDanger),
            ]),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: QubeBar.bg, borderRadius: BorderRadius.circular(10)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.drag_indicator_rounded, size: 16, color: Colors.white70),
              SizedBox(width: 10),
              Icon(Icons.fullscreen_rounded, size: 16, color: qubePink),
              SizedBox(width: 10),
              Icon(Icons.keyboard_arrow_up_rounded, size: 16, color: qubePink),
            ]),
          ),
        ]),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await _font('Inter', ['assets/fonts/Inter-Regular.ttf', 'assets/fonts/Inter-Medium.ttf', 'assets/fonts/Inter-SemiBold.ttf', 'assets/fonts/Inter-Bold.ttf']);
    await _font('Jost', ['assets/fonts/Jost.ttf']);
    final sdk = Platform.environment['FLUTTER_ROOT'] ?? '/sdks/flutter';
    await _font('MaterialIcons', ['$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
  });
  for (final v in [('cm_dark', Brightness.dark, false), ('cm_light', Brightness.light, false), ('cm_ask', Brightness.dark, true)]) {
    testWidgets(v.$1, (t) async {
      t.view.physicalSize = const Size(780, 1240);
      t.view.devicePixelRatio = 2;
      debugDisableShadows = false;
      await t.pumpWidget(_cm(v.$2, ask: v.$3));
      await t.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('preview_${v.$1}.png'));
      debugDisableShadows = true;
    });
  }
  testWidgets('bar', (t) async {
    t.view.physicalSize = const Size(1000, 300);
    t.view.devicePixelRatio = 2;
    debugDisableShadows = false;
    await t.pumpWidget(_bar());
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('preview_bar.png'));
    debugDisableShadows = true;
  });
}
