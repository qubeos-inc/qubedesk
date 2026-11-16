#!/usr/bin/env python3
"""Собирает .github/workflows/qubedesk.yml из сборки RustDesk (upstream-workflows/flutter-build.yml).

Берём только Windows x64 и macOS (Apple Silicon и Intel), без подписей,
публикации и метаданных обновлений RustDesk. Готовые установщики лежат
в артефактах запуска. Запускать после обновления RustDesk:
    python3 .github/scripts/make-qubedesk-workflow.py
"""
import copy, pathlib, yaml

root = pathlib.Path(__file__).resolve().parents[1]
up = yaml.safe_load((root / 'upstream-workflows/flutter-build.yml').read_text())
J = up['jobs']

env = dict(up['env'])
for k in ['ANDROID_SIGNING_KEY', 'MACOS_P12_BASE64']:
    env.pop(k, None)
env.update({'UPLOAD_ARTIFACT': 'true', 'PUBLISH_UPDATE_METADATA': 'false', 'SIGN_BASE_URL': '-2'})

def keep(job, drop):
    j = copy.deepcopy(job)
    names = {s.get('name') for s in j['steps']}
    missing = set(drop) - names
    assert not missing, f'нет шагов: {missing}'
    j['steps'] = [s for s in j['steps'] if s.get('name') not in drop]
    return j

def step_index(job, name):
    return next(i for i, s in enumerate(job['steps']) if s.get('name') == name)

bridge = copy.deepcopy(J['generate-bridge']); bridge.pop('needs', None)
top = copy.deepcopy(J['build-RustDeskTempTopMostWindow']); top.pop('needs', None)
top['strategy']['matrix']['job'] = [m for m in top['strategy']['matrix']['job'] if m['platform'] == 'x64']

win = keep(J['build-for-windows-flutter'], [
    'Run the Rust tests', 'Upload unsigned', 'Sign rustdesk files', 'Verify Windows Flutter version',
    'Verify template payload signatures', 'Build template packer', 'Upload unsigned template packer',
    'Build pre-built MSI template', 'Upload unsigned msi template', 'Sign rustdesk self-extracted file',
    'Upload signed Windows Flutter EXE', 'Upload signed Windows Flutter MSI', 'Publish Release'])
win['strategy']['matrix']['job'] = [m for m in win['strategy']['matrix']['job'] if m['arch'] == 'x86_64']
win['steps'].append({'name': 'qubeDesk: выложить установщики', 'uses': 'actions/upload-artifact@v4',
    'with': {'name': 'qubedesk-windows-x64', 'path': 'SignOutput/*', 'if-no-files-found': 'error'}})

mac = keep(J['build-for-macOS'], [
    'Import the codesign cert', 'Check sign and import sign key', 'Import notarize key', 'Install rcodesign tool',
    'Run the Dart tests', 'Test verified updates', 'Run the Rust tests', 'Upload unsigned macOS app',
    'Codesign app and create signed dmg', 'Upload signed macOS DMG', 'Publish DMG package'])
mac['steps'].insert(step_index(mac, 'Build rustdesk'), {
    'name': 'qubeDesk: значок для macOS', 'shell': 'bash',
    'run': 'set -e\nI=$RUNNER_TEMP/AppIcon.iconset; mkdir -p $I\n'
           'for s in 16 32 128 256 512; do\n'
           '  sips -z $s $s res/mac-icon.png --out $I/icon_${s}x${s}.png >/dev/null\n'
           '  sips -z $((s*2)) $((s*2)) res/mac-icon.png --out $I/icon_${s}x${s}@2x.png >/dev/null\n'
           'done\niconutil -c icns $I -o flutter/macos/Runner/AppIcon.icns\n'})
mac['steps'].append({'name': 'qubeDesk: выложить установщик', 'uses': 'actions/upload-artifact@v4',
    'with': {'name': 'qubedesk-macos-${{ matrix.job.arch }}', 'path': 'rustdesk-*.dmg', 'if-no-files-found': 'error'}})

wf = {
    'name': 'Сборка qubeDesk',
    'on': {'workflow_dispatch': {'inputs': {'upload-artifact': {'type': 'boolean', 'default': True,
                                                                'description': 'Собрать установщики'}}}},
    'env': env,
    'jobs': {'generate-bridge': bridge, 'build-RustDeskTempTopMostWindow': top,
             'build-for-windows-flutter': win, 'build-for-macOS': mac},
}
head = '# Создано .github/scripts/make-qubedesk-workflow.py — правьте сценарий, а не этот файл\n'
out = yaml.safe_dump(wf, allow_unicode=True, sort_keys=False, width=1000)
(root / 'workflows/qubedesk.yml').write_text(head + out)
print('готово:', root / 'workflows/qubedesk.yml')
