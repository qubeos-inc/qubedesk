import 'package:flutter/material.dart';

import 'qube_glass.dart';

/// «Подразделения» как в qubeOS: компьютеры сгруппированы по точкам, в строке —
/// название, номер, связь и кнопка «Подключиться». Компонент только рисует:
/// данные и действия даёт страница (или превью с подставными данными).

class QubeStoreComputer {
  final String id;
  final String name;
  final String platform;
  final bool online;
  /// Кто на нём работает — последний вошедший через qubeOS
  final String? person;
  const QubeStoreComputer(
      {required this.id,
      required this.name,
      required this.platform,
      required this.online,
      this.person});
}

class QubeStoreGroup {
  final String name;
  final List<QubeStoreComputer> computers;
  /// Кому сейчас уходят заявки «Помощи» с этой точки: «ИТ компании · Сергей Иванов»
  final String? helper;
  const QubeStoreGroup(this.name, this.computers, {this.helper});
}

/// Номер группами по три — так его диктуют: 298 564 440
String qubePrettyId(String id) {
  final b = StringBuffer();
  for (var i = 0; i < id.length; i++) {
    final left = id.length - i;
    if (i > 0 && left % 3 == 0) b.write(' ');
    b.write(id[i]);
  }
  return b.toString();
}

String _computers(int n) {
  final d10 = n % 10, d100 = n % 100;
  final w = d10 == 1 && d100 != 11
      ? 'компьютер'
      : d10 >= 2 && d10 <= 4 && (d100 < 12 || d100 > 14)
          ? 'компьютера'
          : 'компьютеров';
  return '$n $w';
}

IconData _iconFor(QubeStoreComputer c) {
  final p = c.platform.toLowerCase();
  final n = c.name.toLowerCase();
  if (n.contains('экран') || n.contains('киоск')) return Icons.tv_rounded;
  if (n.contains('ноутбук') || p.contains('mac')) {
    return Icons.laptop_mac_rounded;
  }
  return Icons.desktop_windows_outlined;
}

class QubeStoreList extends StatefulWidget {
  final List<QubeStoreGroup> groups;
  final void Function(QubeStoreComputer c) onConnect;
  final String emptyText;
  /// Только для превью: строка, будто под мышкой
  final String? highlightId;
  const QubeStoreList(
      {super.key,
      required this.groups,
      required this.onConnect,
      this.highlightId,
      this.emptyText = 'Компьютеров точек пока нет'});

  @override
  State<QubeStoreList> createState() => _QubeStoreListState();
}

class _QubeStoreListState extends State<QubeStoreList> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mut = (dark ? Colors.white : Colors.black).withOpacity(0.55);
    final q = _q.trim().toLowerCase();
    final groups = <QubeStoreGroup>[];
    for (final g in widget.groups) {
      final gm = g.name.toLowerCase().contains(q);
      final list = q.isEmpty || gm
          ? g.computers
          : g.computers
              .where((c) =>
                  c.name.toLowerCase().contains(q) ||
                  (c.person ?? '').toLowerCase().contains(q) ||
                  c.id.contains(q.replaceAll(' ', '')))
              .toList();
      if (list.isNotEmpty) groups.add(QubeStoreGroup(g.name, list, helper: g.helper));
    }

    final search = SizedBox(
      height: 40,
      child: TextField(
        onChanged: (v) => setState(() => _q = v),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Точка, компьютер, сотрудник или номер',
          hintStyle: TextStyle(fontSize: 14, color: mut),
          prefixIcon: Icon(Icons.search_rounded, size: 19, color: mut),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          filled: true,
          fillColor: (dark ? Colors.white : Colors.black).withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );

    return QubeGlass(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: 6),
          Expanded(
            child: groups.isEmpty
                ? Center(
                    child: Text(
                        q.isEmpty ? widget.emptyText : 'Ничего не нашлось',
                        style: TextStyle(fontSize: 14, color: mut)))
                : ListView(
                    padding: const EdgeInsets.only(bottom: 8),
                    children: [
                      for (final g in groups) ...[
                        _GroupHeader(g, mut),
                        for (final c in g.computers)
                          _Row(c, mut, () => widget.onConnect(c),
                              hover: c.id == widget.highlightId),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final QubeStoreGroup g;
  final Color mut;
  const _GroupHeader(this.g, this.mut);

  @override
  Widget build(BuildContext context) {
    final on = g.computers.where((c) => c.online).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
      child: Row(children: [
        const Icon(Icons.storefront_outlined, size: 19, color: qubePink),
        const SizedBox(width: 9),
        // Название — главное: целиком, сокращается только совсем длинное
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(g.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: qubeTitle(17, weight: FontWeight.w600)),
        ),
        const SizedBox(width: 10),
        Text(
            '${_computers(g.computers.length)} · ${on == 0 ? 'никого в сети' : '$on в сети'}',
            maxLines: 1,
            softWrap: false,
            style: TextStyle(fontSize: 12.5, color: mut)),
        const SizedBox(width: 16),
        Expanded(
          child: g.helper == null
              ? const SizedBox.shrink()
              : Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const Icon(Icons.support_outlined, size: 15, color: qubePink),
              const SizedBox(width: 6),
              Flexible(
                child: Text('Помогает: ${g.helper}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: mut)),
              ),
            ]),
        ),
      ]),
    );
  }
}

class _Row extends StatefulWidget {
  final QubeStoreComputer c;
  final Color mut;
  final VoidCallback onConnect;
  final bool hover;
  const _Row(this.c, this.mut, this.onConnect, {this.hover = false});

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  late bool _hover = widget.hover;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = widget.c;
    const green = Color(0xFF34C759);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onDoubleTap: widget.onConnect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _hover
                ? (dark ? Colors.white : Colors.black).withOpacity(0.05)
                : Colors.transparent,
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: qubePink.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(_iconFor(c), size: 18, color: qubePink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w500)),
                  if (c.person != null && c.person!.isNotEmpty)
                    Text(c.person!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: widget.mut)),
                ],
              ),
            ),
            SizedBox(
              width: 116,
              child: Text(qubePrettyId(c.id),
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                      fontSize: 13.5,
                      color: widget.mut,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ),
            SizedBox(
              width: 96,
              child: Row(children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.online ? green : widget.mut)),
                const SizedBox(width: 7),
                Text(c.online ? 'в сети' : 'не в сети',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(fontSize: 13, color: widget.mut)),
              ]),
            ),
            SizedBox(
              width: 150,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _hover ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !_hover,
                    child: _ConnectChip(onTap: widget.onConnect),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ConnectChip extends StatelessWidget {
  final VoidCallback onTap;
  const _ConnectChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: (dark ? Colors.white : Colors.black).withOpacity(0.18)),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.arrow_forward_rounded, size: 16),
          SizedBox(width: 6),
          Text('Подключиться',
              maxLines: 1, softWrap: false, style: TextStyle(fontSize: 13)),
        ]),
      ),
    );
  }
}
