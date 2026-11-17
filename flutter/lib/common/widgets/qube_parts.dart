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
