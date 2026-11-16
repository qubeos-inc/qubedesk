// Снимок нового вида qubeDesk без запуска программы: те же детали интерфейса
// (qube_glass.dart), данные подставные. Запуск:
//   flutter test --update-goldens test/qube_preview_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

Widget _screen(Brightness b) {
  final dark = b == Brightness.dark;
  final mut = (dark ? Colors.white : Colors.black).withOpacity(0.55);
  Widget field(String hint) => Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(dark ? 0.06 : 0.8),
          border: Border.all(
              color: (dark ? Colors.white : Colors.black)
                  .withOpacity(dark ? 0.14 : 0.10)),
        ),
        alignment: Alignment.centerLeft,
        child: Text(hint,
            style: qubeTitle(19, weight: FontWeight.w400)
                .copyWith(color: mut)),
      );
  Widget peer(IconData i, String name, String id, bool on, String when) =>
      Expanded(
        child: QubeGlass(
          radius: 18,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: qubePink.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(i, size: 19, color: qubePink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        Text(id,
                            style: qubeTitle(12.5).copyWith(color: mut)),
                      ]),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: on
                            ? const Color(0xFF34C759)
                            : const Color(0xFF8E8E93))),
                const SizedBox(width: 6),
                Text(on ? 'в сети' : 'не в сети',
                    style: TextStyle(fontSize: 12, color: mut)),
                const Spacer(),
                Text(when, style: TextStyle(fontSize: 12, color: mut)),
              ]),
            ],
          ),
        ),
      );
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
        brightness: b,
        fontFamily: 'Inter',
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.transparent),
    home: Material(
      color: Colors.transparent,
      child: QubeBackdrop(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QubeSidebar(children: [
              const QubeBrand(),
              QubeSideItem(
                  icon: Icons.screen_share_outlined,
                  label: 'Подключиться',
                  selected: true,
                  onTap: () {}),
              const QubeSideLabel('Компьютеры'),
              QubeSideItem(
                  icon: Icons.history_rounded, label: 'Недавние', onTap: () {}),
              QubeSideItem(
                  icon: Icons.star_outline_rounded,
                  label: 'Избранное',
                  onTap: () {}),
              QubeSideItem(
                  icon: Icons.wifi_rounded, label: 'В этой сети', onTap: () {}),
              const QubeSideLabel('Этот компьютер'),
              QubeSideItem(
                  icon: Icons.shield_outlined,
                  label: 'Доступ и пароль',
                  onTap: () {}),
              const Spacer(),
              QubeSideItem(
                  icon: Icons.settings_outlined,
                  label: 'Настройки',
                  onTap: () {}),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: (dark ? Colors.white : Colors.black)
                        .withOpacity(0.05)),
                child: Row(children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 50, 190, 166))),
                  const SizedBox(width: 10),
                  const Text('На связи с qubeOS',
                      style: TextStyle(fontSize: 13)),
                ]),
              ),
            ]),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const QubeHeader('Подключиться',
                        subtitle:
                            'Помогите коллеге или откройте свой компьютер издалека'),
                    const SizedBox(height: 18),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 10,
                            child: QubeGlass(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const QubeCardLabel(
                                      Icons.important_devices_outlined,
                                      'Этот компьютер'),
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Flexible(
                                        child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text('69 983 058',
                                                maxLines: 1,
                                                style: qubeTitle(34)))),
                                    const SizedBox(width: 10),
                                    const QubeIconButton(
                                        icon: Icons.copy_rounded,
                                        tooltip: '',
                                        size: 34),
                                  ]),
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.fromLTRB(
                                        14, 10, 8, 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: Colors.white
                                          .withOpacity(dark ? 0.06 : 0.8),
                                      border: Border.all(
                                          color: (dark
                                                  ? Colors.white
                                                  : Colors.black)
                                              .withOpacity(
                                                  dark ? 0.14 : 0.10)),
                                    ),
                                    child: Row(children: [
                                      Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Одноразовый пароль',
                                                  style: TextStyle(
                                                      fontSize: 11.5,
                                                      color: mut)),
                                              const SizedBox(height: 2),
                                              Text('ffhwfc',
                                                  style: qubeTitle(20)
                                                      .copyWith(
                                                          letterSpacing:
                                                              1.5)),
                                            ]),
                                      ),
                                      const QubeIconButton(
                                          icon: Icons.refresh_rounded,
                                          tooltip: '',
                                          size: 34),
                                      const SizedBox(width: 6),
                                      const QubeIconButton(
                                          icon: Icons.edit_outlined,
                                          tooltip: '',
                                          size: 34),
                                    ]),
                                  ),
                                  const SizedBox(height: 12),
                                  Text('Назовите номер и пароль помощнику.',
                                      style: TextStyle(
                                          fontSize: 12.5, color: mut)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 14,
                            child: QubeGlass(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const QubeCardLabel(
                                      Icons.cast_outlined, 'Другой компьютер'),
                                  const SizedBox(height: 14),
                                  field('Введите удалённый ID'),
                                  const SizedBox(height: 14),
                                  Row(children: const [
                                    QubeButton(
                                        label: 'Подключиться', height: 40),
                                    Spacer(),
                                    QubeIconButton(
                                        icon:
                                            Icons.drive_folder_upload_outlined,
                                        tooltip: ''),
                                    SizedBox(width: 6),
                                    QubeIconButton(
                                        icon: Icons.videocam_outlined,
                                        tooltip: ''),
                                    SizedBox(width: 6),
                                    QubeIconButton(
                                        icon: Icons.terminal_rounded,
                                        tooltip: ''),
                                    SizedBox(width: 8),
                                    QubeIconButton(
                                        icon: Icons.more_horiz, tooltip: ''),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text('Недавние', style: qubeTitle(19)),
                    const SizedBox(height: 10),
                    Row(children: [
                      peer(Icons.desktop_windows_outlined,
                          'Касса — Москва, Тверская', '184 220 913', true,
                          '2 мин назад'),
                      const SizedBox(width: 12),
                      peer(Icons.laptop_mac_outlined, 'Ноутбук Ольги',
                          '93 004 117', true, 'вчера'),
                      const SizedBox(width: 12),
                      peer(Icons.desktop_windows_outlined,
                          'Цех, мастер участка покраски', '58 771 302', false,
                          '3 дня назад'),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await _font('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
      'assets/fonts/Inter-Bold.ttf'
    ]);
    await _font('Jost', ['assets/fonts/Jost.ttf']);
    final sdk = Platform.environment['FLUTTER_ROOT'] ?? '/sdks/flutter';
    await _font('MaterialIcons',
        ['$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
  });
  for (final b in Brightness.values) {
    testWidgets('qubeDesk ${b.name}', (t) async {
      t.view.physicalSize = const Size(2200, 1400);
      t.view.devicePixelRatio = 2;
      // в тестах тени по умолчанию плоские — на время снимка включаем настоящие
      debugDisableShadows = false;
      await t.pumpWidget(_screen(b));
      // картинки в тесте грузятся отдельно — дожидаемся значка, иначе пусто
      await t.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await t.pumpAndSettle();
      await expectLater(
          find.byType(MaterialApp), matchesGoldenFile('preview_${b.name}.png'));
      debugDisableShadows = true;
    });
  }
}
