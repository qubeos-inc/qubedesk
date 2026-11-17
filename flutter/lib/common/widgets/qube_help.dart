import 'package:flutter/material.dart';

import 'qube_glass.dart';

/// «Помощь»: человек у компьютера зовёт специалиста. Заявка уходит в qubeOS —
/// в «Поддержку» фабрики или уведомлением управляющему точкой — уже с номером
/// этого компьютера, так что диктовать ничего не нужно. Компонент только
/// рисует; отправку делает страница.

class QubeHelpTarget {
  final String key;
  final String title;
  final String subtitle;
  const QubeHelpTarget(this.key, this.title, this.subtitle);
}

class QubeHelpView extends StatefulWidget {
  final List<QubeHelpTarget> targets;

  /// Вернуть null — отправлено, иначе текст ошибки для человека
  final Future<String?> Function(String text, String target) onSend;

  /// Нет входа через qubeOS — вместо формы кнопка входа
  final VoidCallback? onLogin;
  const QubeHelpView(
      {super.key, required this.targets, required this.onSend, this.onLogin});

  @override
  State<QubeHelpView> createState() => _QubeHelpViewState();
}

class _QubeHelpViewState extends State<QubeHelpView> {
  final _text = TextEditingController();
  late String _target =
      widget.targets.isEmpty ? '' : widget.targets.first.key;
  bool _busy = false;
  bool _sent = false;
  String? _error;

  Future<void> _send() async {
    if (_text.text.trim().isEmpty || _busy) {
      setState(() => _error = 'Напишите в двух словах, что случилось');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await widget.onSend(_text.text.trim(), _target);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
      _sent = err == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mut = (dark ? Colors.white : Colors.black).withOpacity(0.55);
    final line = (dark ? Colors.white : Colors.black).withOpacity(0.12);

    Widget form;
    if (widget.onLogin != null) {
      form = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Войдите через qubeOS', style: qubeTitle(24)),
          const SizedBox(height: 8),
          Text(
              'Так специалист увидит, кто зовёт и с какой точки, и подключится без пароля.',
              style: TextStyle(fontSize: 14, color: mut, height: 1.4)),
          const SizedBox(height: 18),
          Row(children: [
            QubeButton(label: 'Войти через qubeOS', height: 42, onPressed: widget.onLogin),
          ]),
        ],
      );
    } else if (_sent) {
      final t = widget.targets.firstWhere((t) => t.key == _target,
          orElse: () => const QubeHelpTarget('', 'Специалист', ''));
      form = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: qubePink.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16)),
            child:
                const Icon(Icons.check_rounded, size: 28, color: qubePink),
          ),
          const SizedBox(height: 16),
          Text('Заявка отправлена', style: qubeTitle(24)),
          const SizedBox(height: 8),
          Text(
              '${t.title} получит её в qubeOS вместе с номером этого компьютера. '
              'Когда к вам подключатся, qubeDesk покажет, кто это.',
              style: TextStyle(fontSize: 14, color: mut, height: 1.4)),
          const SizedBox(height: 18),
          TextButton(
            onPressed: () => setState(() {
              _sent = false;
              _text.clear();
            }),
            child: const Text('Позвать ещё раз',
                style: TextStyle(color: qubePink, fontSize: 14)),
          ),
        ],
      );
    } else {
      form = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const QubeCardLabel(Icons.support_outlined, 'Позвать на помощь'),
          const SizedBox(height: 10),
          Text('Что случилось?', style: qubeTitle(24)),
          const SizedBox(height: 14),
          TextField(
            controller: _text,
            minLines: 3,
            maxLines: 5,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Например: не печатается чек',
              hintStyle: TextStyle(color: mut, fontSize: 15),
              filled: true,
              fillColor: Colors.white.withOpacity(dark ? 0.06 : 0.8),
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: line)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: qubePink)),
            ),
          ),
          const SizedBox(height: 14),
          for (final t in widget.targets) ...[
            _Choice(
                t: t,
                selected: t.key == _target,
                mut: mut,
                line: line,
                onTap: () => setState(() => _target = t.key)),
            const SizedBox(height: 10),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_error!,
                  style: const TextStyle(
                      fontSize: 13.5, color: Color(0xFFFF453A))),
            ),
          const SizedBox(height: 4),
          Row(children: [
            QubeButton(
                label: _busy ? 'Отправляем…' : 'Позвать',
                height: 42,
                onPressed: _send),
          ]),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            flex: 14,
            child: QubeGlass(
                padding: const EdgeInsets.all(24), child: form)),
        const SizedBox(width: 14),
        Expanded(
          flex: 10,
          child: QubeGlass(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const QubeCardLabel(
                    Icons.auto_awesome_outlined, 'Как это работает'),
                const SizedBox(height: 14),
                _Step(1, 'Заявка уходит в qubeOS',
                    'с номером компьютера и точкой', mut),
                _Step(2, 'Специалист видит заявку',
                    'и подключается без пароля', mut),
                _Step(3, 'Вы видите, кто подключился',
                    'закончить можно в любой момент', mut),
                _Step(4, 'Всё пишется в журнал',
                    'кто, когда и сколько', mut,
                    last: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  final QubeHelpTarget t;
  final bool selected;
  final Color mut, line;
  final VoidCallback onTap;
  const _Choice(
      {required this.t,
      required this.selected,
      required this.mut,
      required this.line,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? qubePink.withOpacity(0.10) : Colors.transparent,
          border: Border.all(color: selected ? qubePink : line),
        ),
        child: Row(children: [
          Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 22,
              color: selected ? qubePink : mut),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(t.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: mut)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int n;
  final String title, sub;
  final Color mut;
  final bool last;
  const _Step(this.n, this.title, this.sub, this.mut, {this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: qubePink.withOpacity(0.15)),
            child: Text('$n',
                style: const TextStyle(
                    fontSize: 13,
                    color: qubePink,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
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
        ],
      ),
    );
  }
}
