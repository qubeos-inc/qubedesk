import 'package:flutter/material.dart';

import 'qube_glass.dart';

/// Внешний вид «Ждут помощи», плашки обновления и окна «Позвать ещё
/// человека». Только рисуют — данные и действия даёт qube_live.dart
/// (или превью с подставными данными).

Color _mut(BuildContext c) =>
    (Theme.of(c).brightness == Brightness.dark ? Colors.white : Colors.black)
        .withOpacity(0.55);

/// Строка «Ждут помощи»: кто, где, что случилось, сколько ждёт, кнопки.
class QubeWaitRow extends StatelessWidget {
  final IconData icon;
  final String title, sub, when;
  final List<Widget> actions;
  const QubeWaitRow(
      {super.key,
      required this.icon,
      required this.title,
      required this.sub,
      required this.when,
      required this.actions});

  @override
  Widget build(BuildContext context) {
    final mut = _mut(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: QubeGlass(
        radius: 18,
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: qubePink.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 19, color: qubePink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: mut)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(when,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(fontSize: 12.5, color: mut)),
          const SizedBox(width: 12),
          ...actions,
        ]),
      ),
    );
  }
}

/// Плашка «Вышла версия …» в боковой панели.
class QubeUpdateCard extends StatelessWidget {
  final String label, notes;
  final double? progress;
  final String? done;
  final VoidCallback onUpdate;
  const QubeUpdateCard(
      {super.key,
      required this.label,
      required this.notes,
      required this.onUpdate,
      this.progress,
      this.done});

  @override
  Widget build(BuildContext context) {
    final mut = _mut(context);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: qubePink.withOpacity(0.12),
        border: Border.all(color: qubePink.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.system_update_alt_rounded,
                size: 18, color: qubePink),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Вышла версия $label',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ]),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(notes,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: mut, height: 1.35)),
          ],
          const SizedBox(height: 10),
          if (done != null)
            Text(done!, style: const TextStyle(fontSize: 12.5, height: 1.35))
          else if (progress != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: progress == 0 ? null : progress,
                  minHeight: 6,
                  color: qubePink,
                  backgroundColor: qubePink.withOpacity(0.15)),
            )
          else
            QubeButton(label: 'Обновить', height: 34, onPressed: onUpdate),
        ],
      ),
    );
  }
}

/// Окно «Позвать ещё человека».
class QubeInviteView extends StatelessWidget {
  final List<dynamic> people;
  final bool viewOnly;
  final String? error;
  final ValueChanged<bool> onViewOnly;
  final ValueChanged<String> onSearch;
  final ValueChanged<dynamic> onPick;
  final bool autofocus;
  const QubeInviteView(
      {super.key,
      required this.people,
      required this.viewOnly,
      required this.onViewOnly,
      required this.onSearch,
      required this.onPick,
      this.error,
      this.autofocus = true});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mut = _mut(context);
    return SizedBox(
      width: 460,
      height: 520,
      child: QubeGlass(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Позвать ещё человека', style: qubeTitle(22)),
            const SizedBox(height: 4),
            Text('Он подключится к этому же экрану без пароля',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: mut)),
            const SizedBox(height: 14),
            TextField(
              autofocus: autofocus,
              style: const TextStyle(fontSize: 15),
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: 'Имя или фамилия',
                hintStyle: TextStyle(color: mut),
                prefixIcon: Icon(Icons.search_rounded, size: 19, color: mut),
                filled: true,
                fillColor:
                    (dark ? Colors.white : Colors.black).withOpacity(0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => onViewOnly(!viewOnly),
              child: Row(children: [
                Switch(
                    value: viewOnly,
                    activeColor: qubePink,
                    onChanged: onViewOnly),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Только смотреть — без мыши и клавиатуры',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14)),
                ),
              ]),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(error!,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFFFF453A))),
              ),
            const SizedBox(height: 6),
            Expanded(
              child: ListView(children: [
                for (final p in people)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onPick(p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 9, horizontal: 6),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: qubePink.withOpacity(0.16),
                          child: Text(
                              '${p['name']}'.isEmpty
                                  ? '?'
                                  : '${p['name']}'.substring(0, 1),
                              style: const TextStyle(
                                  color: qubePink,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${p['name']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14.5)),
                              if ('${p['sub']}'.isNotEmpty)
                                Text('${p['sub']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        TextStyle(fontSize: 12.5, color: mut)),
                            ],
                          ),
                        ),
                        const Icon(Icons.send_rounded,
                            size: 17, color: qubePink),
                      ]),
                    ),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Окно на компьютере, к которому подключились ─────────────────────

const Color qubeDanger = Color(0xFFFF453A);
const Color qubeOk = Color(0xFF34C759);

/// Номер группами по три: 69 983 058
String qubeId(String id) {
  final d = id.replaceAll(' ', '');
  final b = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i > 0 && (d.length - i) % 3 == 0) b.write(' ');
    b.write(d[i]);
  }
  return b.toString();
}

/// Шапка: кто подключился. «Имя · qubeOS» показываем именем и меткой «qubeOS».
class QubeClientHeader extends StatelessWidget {
  final String name, peerId, status;
  final String? kind;
  final bool live;
  final VoidCallback? onChat;
  const QubeClientHeader(
      {super.key,
      required this.name,
      required this.peerId,
      required this.status,
      this.kind,
      this.live = true,
      this.onChat});

  @override
  Widget build(BuildContext context) {
    final mut = _mut(context);
    final fromQube = name.endsWith(' · qubeOS');
    final who = fromQube ? name.substring(0, name.length - 9) : name;
    return QubeGlass(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
                colors: [qubePink, qubePinkSoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
          child: Text(who.isEmpty ? '?' : who.characters.first.toUpperCase(),
              style: qubeTitle(26, weight: FontWeight.w600)
                  .copyWith(color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: Text(who,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: qubeTitle(17, weight: FontWeight.w600)),
                ),
                if (fromQube) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: qubePink.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('qubeOS',
                        style: TextStyle(
                            fontSize: 10.5,
                            color: qubePink,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
              const SizedBox(height: 2),
              Text(
                  kind == null
                      ? qubeId(peerId)
                      : '${qubeId(peerId)} · $kind',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: mut)),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: live ? qubeOk : mut)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5)),
                ),
              ]),
            ],
          ),
        ),
        if (onChat != null)
          QubeIconButton(
              icon: Icons.chat_bubble_outline_rounded,
              tooltip: 'Чат',
              size: 36,
              onTap: onChat),
      ]),
    );
  }
}

/// Плитка разрешения: включено — розовая, выключено — серая; подпись снизу.
class QubePermTile extends StatelessWidget {
  final bool enabled, canModify;
  final IconData icon;
  final String label, tooltip;
  final VoidCallback? onTap;
  const QubePermTile(
      {super.key,
      required this.enabled,
      required this.icon,
      required this.label,
      required this.tooltip,
      this.canModify = true,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mut = _mut(context);
    return Tooltip(
      message: '$tooltip: ${enabled ? 'включено' : 'выключено'}',
      waitDuration: Duration.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: canModify ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: enabled
                ? qubePink.withOpacity(canModify ? 0.16 : 0.09)
                : (dark ? Colors.white : Colors.black).withOpacity(0.05),
            border: Border.all(
                color: enabled
                    ? qubePink.withOpacity(0.35)
                    : (dark ? Colors.white : Colors.black).withOpacity(0.08)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 21, color: enabled ? qubePink : mut),
              const SizedBox(height: 4),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10.5, color: enabled ? null : mut)),
            ],
          ),
        ),
      ),
    );
  }
}

enum QubeCmKind { primary, danger, neutral }

/// Кнопка окна подключения: главная — розовая, «Отключить» — красная.
class QubeCmButton extends StatelessWidget {
  final String text;
  final QubeCmKind kind;
  final Widget? icon;
  final GestureTapCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  const QubeCmButton(
      {super.key,
      required this.text,
      this.kind = QubeCmKind.neutral,
      this.icon,
      this.onTap,
      this.onTapDown});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final r = BorderRadius.circular(14);
    final fg = kind == QubeCmKind.neutral
        ? (dark ? Colors.white : qubeInk)
        : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        onTapDown: onTapDown,
        child: Ink(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: kind == QubeCmKind.primary
                ? const LinearGradient(colors: [qubePink, qubePinkSoft])
                : null,
            color: kind == QubeCmKind.danger
                ? qubeDanger
                : kind == QubeCmKind.neutral
                    ? (dark ? Colors.white : Colors.black).withOpacity(0.08)
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                IconTheme(
                    data: IconThemeData(color: fg, size: 17), child: icon!),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: fg,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Панель во время подключения ─────────────────────────────────────

/// Цвета панели: тёмное стекло, кнопки — светлая подложка, наведение — розовый
class QubeBar {
  static const Color bg = Color(0xEB1C1C1E);
  static const Color button = Color(0x1FFFFFFF);
  static const Color hover = qubePink;
  static const Color active = Color(0x59F747A2);
  static const Color close = Color(0x40FF453A);
  static const Color closeHover = qubeDanger;
  static const double size = 34;
  static const double radius = 10;
}
