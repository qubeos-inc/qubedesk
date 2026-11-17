// Превью настроек qubeDesk и верхней полосы вкладок в стиле qubeOS.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/common/widgets/qube_glass.dart';

Future<void> _font(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.view(File(f).readAsBytesSync().buffer)));
  }
  await l.load();
}

Widget _tab(BuildContext c, IconData i, String t, bool sel) {
  final dark = Theme.of(c).brightness == Brightness.dark;
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: sel ? qubePink.withOpacity(0.16) : Colors.transparent),
    child: Row(children: [
      Icon(i, size: 16, color: sel ? qubePink : qubePinkSoft),
      const SizedBox(width: 6),
      Text(t, style: TextStyle(fontSize: 13, color: sel ? (dark ? Colors.white : qubeInk) : (dark ? Colors.white60 : Colors.black54))),
      if (sel) ...[const SizedBox(width: 8), Icon(Icons.close_rounded, size: 14, color: dark ? Colors.white54 : Colors.black45)],
    ]),
  );
}

Widget _row(String t, {bool on = true, String? sub}) => Builder(builder: (c) {
      final dark = Theme.of(c).brightness == Brightness.dark;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Row(children: [
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: const TextStyle(fontSize: 14)),
            if (sub != null) Text(sub, style: TextStyle(fontSize: 12, color: dark ? Colors.white54 : Colors.black45)),
          ])),
          Switch(value: on, onChanged: (_) {}, activeColor: Colors.white, activeTrackColor: qubePink),
        ]),
      );
    });

Widget _card(String title, List<Widget> rows) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 16, 0),
      child: QubeGlass(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 8), child: Text(title, style: qubeTitle(17, weight: FontWeight.w600))),
          ...rows,
        ]),
      ),
    );

Widget _app(Brightness b) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: b, fontFamily: 'Inter', useMaterial3: false),
      home: Material(
        color: Colors.transparent,
        child: QubeBackdrop(
          child: Builder(builder: (c) {
            final dark = Theme.of(c).brightness == Brightness.dark;
            return Column(children: [
              SizedBox(
                height: 40,
                child: Row(children: [
                  const SizedBox(width: 12),
                  Container(width: 22, height: 22, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), gradient: const LinearGradient(colors: [qubePink, qubePinkSoft])),
                      child: const Center(child: Text('q', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
                  const SizedBox(width: 8),
                  _tab(c, Icons.home_rounded, 'Главная', false),
                  _tab(c, Icons.settings_rounded, 'Настройки', true),
                  const Spacer(),
                  for (final i in [Icons.remove_rounded, Icons.crop_square_rounded, Icons.close_rounded])
                    SizedBox(width: 44, child: Icon(i, size: 16, color: dark ? Colors.white70 : Colors.black54)),
                ]),
              ),
              Expanded(
                child: Row(children: [
                  QubeSidebar(children: [
                    Padding(padding: const EdgeInsets.fromLTRB(10, 8, 10, 14), child: Text('Настройки', style: qubeTitle(26, weight: FontWeight.w600))),
                    QubeSideItem(icon: Icons.settings_rounded, label: 'Основные', selected: true, onTap: () {}),
                    QubeSideItem(icon: Icons.lock_outline_rounded, label: 'Безопасность', onTap: () {}),
                    QubeSideItem(icon: Icons.link_rounded, label: 'Сеть', onTap: () {}),
                    QubeSideItem(icon: Icons.desktop_windows_outlined, label: 'Экран', onTap: () {}),
                    QubeSideItem(icon: Icons.person_outline_rounded, label: 'Учётная запись', onTap: () {}),
                    QubeSideItem(icon: Icons.print_outlined, label: 'Принтер', onTap: () {}),
                    QubeSideItem(icon: Icons.info_outline_rounded, label: 'О программе', onTap: () {}),
                  ]),
                  Expanded(
                    child: ListView(children: [
                      _card('Язык', [Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 8), child: Text('Русский', style: TextStyle(fontSize: 14, color: dark ? Colors.white : qubeInk)))]),
                      _card('Тема', [_row('Как в системе', on: true), _row('Тёмная', on: false)]),
                      _card('Служба', [_row('Запускать при входе в Windows', sub: 'Чтобы к компьютеру можно было подключиться сразу'), _row('Принимать входящие подключения')]),
                    ]),
                  ),
                ]),
              ),
            ]);
          }),
        ),
      ),
    );

void main() {
  setUpAll(() async {
    await _font('Inter', ['assets/fonts/Inter-Regular.ttf', 'assets/fonts/Inter-Medium.ttf', 'assets/fonts/Inter-SemiBold.ttf', 'assets/fonts/Inter-Bold.ttf']);
    await _font('Jost', ['assets/fonts/Jost.ttf']);
    final sdk = Platform.environment['FLUTTER_ROOT'] ?? '/sdks/flutter';
    await _font('MaterialIcons', ['$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
  });
  for (final v in [('settings_dark', Brightness.dark), ('settings_light', Brightness.light)]) {
    testWidgets(v.$1, (t) async {
      t.view.physicalSize = const Size(1800, 1200);
      t.view.devicePixelRatio = 2;
      await t.pumpWidget(_app(v.$2));
      await t.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('preview_${v.$1}.png'));
    });
  }
}
