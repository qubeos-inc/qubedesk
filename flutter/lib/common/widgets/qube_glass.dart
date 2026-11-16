import 'dart:ui';

import 'package:flutter/material.dart';

/// Материалы qubeDesk — те же, что в qubeOS: розовое свечение на фоне и
/// матовое стекло поверх. Стекло без фона под ним не видно, поэтому главное
/// окно всегда кладёт панели на [QubeBackdrop].

const Color qubePink = Color(0xFFF747A2);
const Color qubePinkSoft = Color(0xFFED99BB);
const Color qubeInk = Color(0xFF141414);
const Color qubePaper = Color(0xFFF9F9F9);

bool _dark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

/// Фон окна: ровный цвет темы и два размытых розовых пятна, как обои qubeOS.
class QubeBackdrop extends StatelessWidget {
  final Widget child;
  const QubeBackdrop({super.key, required this.child});

  Widget _blob(Color c, double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c, c.withOpacity(0)]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final dark = _dark(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: dark ? qubeInk : qubePaper),
        Positioned(
          left: -220,
          top: -260,
          child: _blob(qubePink.withOpacity(dark ? 0.38 : 0.28), 720),
        ),
        Positioned(
          right: -260,
          bottom: -300,
          child: _blob(qubePinkSoft.withOpacity(dark ? 0.26 : 0.34), 760),
        ),
        child,
      ],
    );
  }
}

/// Стеклянная панель: размытие того, что под ней, полупрозрачная заливка,
/// светлая кромка и блик сверху — свет приходит сверху, как в qubeOS.
class QubeGlass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  const QubeGlass({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final dark = _dark(context);
    final r = BorderRadius.circular(radius);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.22 : 0.06),
            blurRadius: 40,
            spreadRadius: -6,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.35],
                colors: [
                  Colors.white.withOpacity(dark ? 0.10 : 0.80),
                  Colors.white.withOpacity(dark ? 0.04 : 0.55),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(dark ? 0.12 : 0.85),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Главная кнопка: розовая капсула с градиентом, как «+» в qubeOS.
class QubeButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  const QubeButton(
      {super.key, required this.label, this.onPressed, this.height = 34});

  @override
  State<QubeButton> createState() => _QubeButtonState();
}

class _QubeButtonState extends State<QubeButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.height),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [qubePink, qubePinkSoft],
              ),
              boxShadow: [
                BoxShadow(
                  color: qubePink.withOpacity(_hover ? 0.45 : 0.28),
                  blurRadius: _hover ? 26 : 18,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Заголовки — Jost, как в qubeOS. Шрифт переменный, вес задаём осью wght.
TextStyle qubeTitle(double size, {FontWeight weight = FontWeight.w500}) =>
    TextStyle(
      fontFamily: 'Jost',
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
    );

Color _mut(BuildContext context, [double o = 0.55]) =>
    (Theme.of(context).textTheme.titleLarge?.color ?? Colors.grey)
        .withOpacity(o);

/// Боковая панель как в приложениях qubeOS: плотнее стекла карточек, чтобы
/// пункты читались поверх розового свечения.
class QubeSidebar extends StatelessWidget {
  final List<Widget> children;
  const QubeSidebar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final dark = _dark(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: 232,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          decoration: BoxDecoration(
            color: dark
                ? const Color(0xFF1C1C1E).withOpacity(0.72)
                : Colors.white.withOpacity(0.70),
            border: Border(
              right: BorderSide(
                  color: Colors.white.withOpacity(dark ? 0.10 : 0.9)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Значок приложения и название в шапке боковой панели.
class QubeBrand extends StatelessWidget {
  const QubeBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: qubePink.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset('assets/icon.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('qubeDesk',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: qubeTitle(19)),
                Text('Удалённый доступ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: _mut(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Подпись группы в боковой панели: «КОМПЬЮТЕРЫ», «ЭТОТ КОМПЬЮТЕР».
class QubeSideLabel extends StatelessWidget {
  final String text;
  const QubeSideLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
        child: Text(text.toUpperCase(),
            maxLines: 1,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.9,
                color: _mut(context, 0.4))),
      );
}

/// Пункт боковой панели. Выбранный — розовая подложка и полоска слева.
class QubeSideItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const QubeSideItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  State<QubeSideItem> createState() => _QubeSideItemState();
}

class _QubeSideItemState extends State<QubeSideItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dark = _dark(context);
    final sel = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: sel
                    ? qubePink.withOpacity(dark ? 0.16 : 0.12)
                    : _hover
                        ? (dark ? Colors.white : Colors.black)
                            .withOpacity(dark ? 0.06 : 0.04)
                        : Colors.transparent,
              ),
              child: Row(
                children: [
                  Icon(widget.icon,
                      size: 18, color: sel ? qubePink : _mut(context)),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
            if (sel)
              Positioned(
                left: -12,
                top: 8,
                bottom: 10,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                      color: qubePink, borderRadius: BorderRadius.circular(3)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Заголовок экрана: крупно Jost и строка пояснения.
class QubeHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  const QubeHeader(this.title,
      {super.key, this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: qubeTitle(30)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.5, color: _mut(context))),
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      );
}

/// Подпись карточки: розовый значок и заглавные буквы.
class QubeCardLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const QubeCardLabel(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: qubePink),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: _mut(context))),
          ),
        ],
      );
}

/// Круглая кнопка-значок с подсказкой: «Файлы», «Камера», «Терминал».
class QubeIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final double size;
  const QubeIconButton(
      {super.key,
      required this.icon,
      required this.tooltip,
      this.onTap,
      this.size = 40});

  @override
  State<QubeIconButton> createState() => _QubeIconButtonState();
}

class _QubeIconButtonState extends State<QubeIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dark = _dark(context);
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hover
                  ? (dark ? Colors.white : Colors.black)
                      .withOpacity(dark ? 0.08 : 0.05)
                  : Colors.transparent,
              border: Border.all(
                  color: (dark ? Colors.white : Colors.black)
                      .withOpacity(dark ? 0.14 : 0.10)),
            ),
            child: Icon(widget.icon,
                size: 18, color: _hover ? qubePink : _mut(context)),
          ),
        ),
      ),
    );
  }
}
