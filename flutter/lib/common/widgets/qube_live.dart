import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart' hide Dialog;
import 'package:flutter_hbb/models/peer_model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as raw;
import 'package:path_provider/path_provider.dart';

import '../../utils/http_service.dart' as http;
import 'qube_glass.dart';
import 'qube_help.dart';
import 'qube_parts.dart';
import 'qube_stores.dart';

/// Живые экраны qubeDesk поверх компонентов из qube_stores / qube_help:
/// данные берутся из qubeOS по пропуску входа.

String _msg(dynamic j, int code) {
  if (j is Map && j['message'] != null) {
    final m = j['message'];
    return m is List ? m.join(', ') : m.toString();
  }
  if (j is Map && j['error'] != null) return j['error'].toString();
  return code == 401
      ? 'Войдите в qubeDesk через qubeOS'
      : 'Нет связи с qubeOS, попробуйте ещё раз';
}

/// Запрос к qubeOS от имени вошедшего человека. Ошибка — понятным текстом.
Future<dynamic> qubeApi(String path,
    {Map<String, String>? query, Object? body}) async {
  final base = '${await bind.mainGetApiServer()}/api/$path';
  final uri = Uri.parse(base).replace(queryParameters: query);
  final headers = {...getHttpHeaders(), 'Content-Type': 'application/json'};
  final resp = body == null
      ? await http.get(uri, headers: headers)
      : await http.post(uri, headers: headers, body: jsonEncode(body));
  dynamic j;
  try {
    j = jsonDecode(decode_http_response(resp));
  } catch (_) {}
  if (resp.statusCode >= 300) throw _msg(j, resp.statusCode);
  return j;
}

/// Номер этого компьютера (без пробелов)
Future<String> _myId() async =>
    (await bind.mainGetMyId()).replaceAll(' ', '');

// ── Подразделения ───────────────────────────────────────────────────

class QubeStoresLive extends StatefulWidget {
  const QubeStoresLive({super.key});
  @override
  State<QubeStoresLive> createState() => _QubeStoresLiveState();
}

/// Данные берём прямо из qubeOS (stores-view): точки, компьютеры, кто на них
/// работает, на связи ли и кто помогает. Раньше группы собирались из списка
/// RustDesk, и название точки по дороге терялось — всё падало в «Без точки».
class _QubeStoresLiveState extends State<QubeStoresLive> {
  List<QubeStoreGroup>? _groups;
  String? _error;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _load();
    _t = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await qubeApi('stores-view') as List;
      final groups = [
        for (final g in list)
          QubeStoreGroup(
            '${g['name']}',
            [
              for (final c in (g['computers'] as List))
                QubeStoreComputer(
                  id: '${c['id']}',
                  name: '${c['name']}',
                  platform: '${c['os'] ?? ''}',
                  online: c['online'] == true,
                  person: c['person'] as String?,
                ),
            ],
            helper: g['helper'] == null
                ? null
                : ('${g['helper']['names']}'.isEmpty
                    ? '${g['helper']['title']}'
                    : '${g['helper']['title']}' == 'Поддержка фабрики'
                        ? 'Поддержка фабрики'
                        : '${g['helper']['names']} · ${'${g['helper']['title']}'.toLowerCase()}'),
          ),
      ];
      if (mounted) setState(() { _groups = groups; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_groups == null) {
      return Center(
          child: _error == null
              ? const CircularProgressIndicator(color: qubePink)
              : Text(_error!, style: const TextStyle(fontSize: 14)));
    }
    return QubeStoreList(
      groups: _groups!,
      emptyText: 'Компьютеров точек пока нет — их добавляют в карточке подразделения в qubeOS',
      onConnect: (c) => connect(context, c.id),
    );
  }
}

// ── Помощь ──────────────────────────────────────────────────────────

class QubeHelpLive extends StatefulWidget {
  final VoidCallback onLogin;
  const QubeHelpLive({super.key, required this.onLogin});
  @override
  State<QubeHelpLive> createState() => _QubeHelpLiveState();
}

class _QubeHelpLiveState extends State<QubeHelpLive> {
  List<QubeHelpTarget>? _targets;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!gFFI.userModel.isLogin) return;
    try {
      final list = await qubeApi('help/targets', query: {'id': await _myId()});
      setState(() => _targets = [
            for (final t in list as List)
              QubeHelpTarget('${t['level']}', '${t['title']}', '${t['subtitle']}')
          ]);
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!gFFI.userModel.isLogin) {
      return QubeHelpView(
          targets: const [],
          onSend: (_, __) async => null,
          onLogin: widget.onLogin);
    }
    if (_targets == null) {
      return Center(
          child: _error == null
              ? const CircularProgressIndicator(color: qubePink)
              : Text(_error!, style: const TextStyle(fontSize: 14)));
    }
    return QubeHelpView(
      targets: _targets!,
      onSend: (text, level) async {
        try {
          await qubeApi('help',
              body: {'id': await _myId(), 'text': text, 'level': int.parse(level)});
          return null;
        } catch (e) {
          return '$e';
        }
      },
    );
  }
}

// ── Ждут помощи (на главном экране у специалиста) ───────────────────

class QubeWaiting extends StatefulWidget {
  /// Только для превью: подставные заявки и приглашения
  final List<dynamic>? demoAsks, demoInvites;
  const QubeWaiting({super.key, this.demoAsks, this.demoInvites});
  @override
  State<QubeWaiting> createState() => _QubeWaitingState();
}

class _QubeWaitingState extends State<QubeWaiting> {
  late List<dynamic> _asks = widget.demoAsks ?? [];
  late List<dynamic> _invites = widget.demoInvites ?? [];
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (widget.demoAsks != null) return;
    _load();
    _t = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!gFFI.userModel.isLogin) return;
    try {
      final r = await Future.wait([qubeApi('help/inbox'), qubeApi('invites')]);
      if (!mounted) return;
      setState(() {
        _asks = r[0] as List;
        _invites = r[1] as List;
      });
    } catch (_) {}
  }

  String _ago(String iso) {
    final m = int.tryParse(iso) ?? DateTime.now().difference(DateTime.parse(iso)).inMinutes;
    if (m < 1) return 'сейчас';
    if (m < 60) return '$m мин';
    return '${m ~/ 60} ч';
  }

  Future<void> _take(dynamic a) async {
    try {
      if (a['mine'] != true) await qubeApi('help/${a['id']}/take', body: {});
      if (mounted) connect(context, '${a['deviceId']}');
      _load();
    } catch (e) {
      showToast('$e');
      _load();
    }
  }

  Future<void> _done(dynamic a) async {
    try {
      await qubeApi('help/${a['id']}/done', body: {});
      showToast('Заявка закрыта — спасибо за помощь');
      _load();
    } catch (e) {
      showToast('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_asks.isEmpty && _invites.isEmpty) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mut = (dark ? Colors.white : Colors.black).withOpacity(0.55);
    Widget row(IconData icon, String title, String sub, String when,
            List<Widget> actions) =>
        QubeWaitRow(icon: icon, title: title, sub: sub, when: when, actions: actions);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 22),
        Text('Ждут помощи', maxLines: 1, style: qubeTitle(19)),
        const SizedBox(height: 10),
        for (final i in _invites)
          row(
              Icons.group_add_outlined,
              '${i['who']} зовёт ${i['viewOnly'] == true ? 'посмотреть' : 'подключиться'}',
              '${i['computer']}${(i['store'] ?? '') != '' ? ' · ${i['store']}' : ''}',
              _ago('${i['createdAt']}'),
              [
                QubeButton(
                    label: 'Присоединиться',
                    height: 36,
                    onPressed: () => connect(context, '${i['deviceId']}')),
              ]),
        for (final a in _asks)
          row(
              Icons.support_outlined,
              '${a['who']} · ${a['computer']}${(a['store'] ?? '') != '' ? ', ${a['store']}' : ''}',
              '«${a['text']}»',
              _ago('${a['createdAt']}'),
              [
                if (a['mine'] == true)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: QubeIconButton(
                        icon: Icons.check_rounded,
                        tooltip: 'Помощь оказана — закрыть заявку',
                        onTap: () => _done(a)),
                  ),
                QubeButton(
                    label: a['mine'] == true ? 'Подключиться' : 'Взять',
                    height: 36,
                    onPressed: () => _take(a)),
              ]),
      ],
    );
  }
}

// ── Пригласить ещё человека в подключение ───────────────────────────

/// Вошёл ли человек через qubeOS (работает и в окне подключения)
bool qubeLoggedIn() =>
    bind.mainGetLocalOption(key: 'access_token').isNotEmpty;

/// Окно «Позвать ещё человека»: поиск по qubeOS, «только смотреть», отправка.
/// Приглашённому приходит уведомление; qubeDesk пустит его без пароля.
Future<void> showQubeInvite(BuildContext context, String deviceId) => showDialog(
    context: context,
    builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: QubeInviteBody(deviceId: deviceId.replaceAll(' ', ''))));

class QubeInviteBody extends StatefulWidget {
  final String deviceId;
  /// Только для превью: подставной список людей
  final List<dynamic>? demoPeople;
  const QubeInviteBody({super.key, required this.deviceId, this.demoPeople});
  @override
  State<QubeInviteBody> createState() => _QubeInviteBodyState();
}

class _QubeInviteBodyState extends State<QubeInviteBody> {
  late List<dynamic> _people = widget.demoPeople ?? [];
  bool _viewOnly = true;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.demoPeople == null) _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(String v) async {
    try {
      final r = await qubeApi('invite/people', query: {'id': widget.deviceId, 'q': v});
      if (mounted) setState(() { _people = r as List; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _send(dynamic p) async {
    try {
      await qubeApi('invite', body: {'id': widget.deviceId, 'userId': p['id'], 'viewOnly': _viewOnly});
      showToast('${p['name']} получит приглашение в qubeOS');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) => QubeInviteView(
        people: _people,
        viewOnly: _viewOnly,
        error: _error,
        autofocus: widget.demoPeople == null,
        onViewOnly: (v) => setState(() => _viewOnly = v),
        onSearch: (v) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 250), () => _search(v));
        },
        onPick: _send,
      );
}

// ── Обновление внутри программы ─────────────────────────────────────

/// Номер этой сборки (q7, q8 …). qubeOS сообщает номер последней; больше —
/// значит, вышла новая версия. Поднимается к каждому выпуску.
const int qubeBuild = 8;

/// Плашка «Вышла новая версия» в боковой панели: скачивает установщик сама
/// и открывает его — ходить на GitHub не нужно.
class QubeUpdateBanner extends StatefulWidget {
  final Map<String, dynamic>? demo;
  const QubeUpdateBanner({super.key, this.demo});
  @override
  State<QubeUpdateBanner> createState() => _QubeUpdateBannerState();
}

class _QubeUpdateBannerState extends State<QubeUpdateBanner> {
  late Map<String, dynamic>? _latest = widget.demo;
  double? _progress;
  String? _done;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (widget.demo != null) return;
    _check();
    _t = Timer.periodic(const Duration(hours: 3), (_) => _check());
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final j = await qubeApi('version');
      if (j is Map && (j['build'] ?? 0) is int && j['build'] > qubeBuild) {
        if (mounted) setState(() => _latest = Map<String, dynamic>.from(j));
      }
    } catch (_) {}
  }

  Future<void> _update() async {
    final l = _latest!;
    // Mac на Apple и на Intel — разные установщики: берём под свой процессор
    final arm = Platform.version.contains('arm64');
    final url = '${Platform.isWindows ? l['windows'] : (arm ? l['macArm'] : l['macIntel']) ?? l['mac'] ?? ''}';
    if (url.isEmpty || !url.startsWith('https://')) {
      showToast('Для этой системы новой версии пока нет');
      return;
    }
    setState(() => _progress = 0);
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${Uri.parse(url).pathSegments.last}');
      final resp = await raw.Client().send(raw.Request('GET', Uri.parse(url)));
      if (resp.statusCode != 200) throw 'код ${resp.statusCode}';
      final total = resp.contentLength ?? 0;
      var got = 0;
      final sink = file.openWrite();
      await for (final chunk in resp.stream) {
        sink.add(chunk);
        got += chunk.length;
        if (total > 0 && mounted) setState(() => _progress = got / total);
      }
      await sink.close();
      if (Platform.isWindows) {
        // Запустить установщик рядом с работающей программой нельзя: он видит
        // открытый qubeDesk и отдаёт ему управление — окно установки не
        // появляется. Ставим тихо, с правами администратора: установщик сам
        // закроет старую версию, а затем открываем новую
        final exe = file.path.replaceAll("'", "''");
        await Process.start('powershell.exe', [
          '-NoProfile', '-WindowStyle', 'Hidden', '-Command',
          "Start-Process -FilePath '$exe' -ArgumentList '--silent-install' -Verb RunAs -Wait; "
              "Start-Sleep 3; \$p = Join-Path \$env:ProgramFiles 'qubeDesk\\qubeDesk.exe'; "
              "if (Test-Path \$p) { Start-Process \$p }",
        ], mode: ProcessStartMode.detached);
        _done = 'Windows спросит разрешение — нажмите «Да». qubeDesk обновится и откроется сам';
      } else {
        await Process.run('open', [file.path]);
        _done = 'Перетащите qubeDesk в «Программы» и замените старую';
      }
    } catch (e) {
      showToast('Не получилось скачать обновление, попробуйте позже');
    }
    if (mounted) setState(() => _progress = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = _latest;
    if (l == null) return const SizedBox.shrink();
    return QubeUpdateCard(
        label: '${l['label'] ?? ''}',
        notes: '${l['notes'] ?? ''}',
        progress: _progress,
        done: _done,
        onUpdate: _update);
  }
}
