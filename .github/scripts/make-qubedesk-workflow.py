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
# build.py докладывает service в уже подписанный пакет — подпись ломается,
# и macOS называет программу «повреждённой». Без сертификата Apple ставим
# ad-hoc подпись на весь пакет заново, перед упаковкой в dmg.
mac['steps'].insert(step_index(mac, 'create unsigned dmg'), {
    'name': 'qubeDesk: подпись ad-hoc', 'shell': 'bash',
    'run': 'set -e\nAPP=./flutter/build/macos/Build/Products/Release/qubeDesk.app\n'
           'codesign --force --deep --sign - "$APP"\ncodesign --verify --deep --strict --verbose=2 "$APP"\n'})

# Программа называется qubeDesk.app, установщики — qubedesk-…
for st in mac['steps']:
    if st.get('name') == 'create unsigned dmg':
        st['run'] = st['run'].replace('RustDesk.app', 'qubeDesk.app').replace('rustdesk-${{ env.VERSION }}', 'qubedesk-${{ env.VERSION }}')
    if st.get('name') == 'Rename rustdesk':
        st['run'] = st['run'].replace('rustdesk-', 'qubedesk-')
for st in win['steps']:
    if st.get('name') == 'Build self-extracted executable':
        st['run'] = st['run'].replace('SignOutput/rustdesk-', 'SignOutput/qubedesk-')
    if st.get('name') == 'Build msi':
        # MSI под именем qubeDesk ищет qubeDesk.exe — так программа и будет называться у людей
        st['run'] = ('Move-Item -Force ./rustdesk/rustdesk.exe ./rustdesk/qubeDesk.exe\n' + st['run'].replace('preprocess.py --arp -d', 'preprocess.py --arp -c --app-name qubeDesk --manufacturer qubeOS -d')
                     .replace('SignOutput/rustdesk-', 'SignOutput/qubedesk-'))
for st, want in [(s, 'qubedesk-') for s in mac['steps'] + win['steps'] if s.get('name') in ('create unsigned dmg', 'Build self-extracted executable', 'Build msi')]:
    assert want in st['run'], st['name']

mac['steps'].append({'name': 'qubeDesk: выложить установщик', 'uses': 'actions/upload-artifact@v4',
    'with': {'name': 'qubedesk-macos-${{ matrix.job.arch }}', 'path': 'qubedesk-*.dmg', 'if-no-files-found': 'error'}})

wf = {
    'name': 'Сборка qubeDesk',
    'on': {'workflow_dispatch': {'inputs': {'upload-artifact': {'type': 'boolean', 'default': True,
                                                                'description': 'Собрать установщики'}}}},
    'env': env,
    'jobs': {'generate-bridge': bridge, 'build-RustDeskTempTopMostWindow': top,
             'build-for-windows-flutter': win, 'build-for-macOS': mac},
}
# Отдельный запуск только для Mac на Apple (M1–M4): у GitHub часто нет
# свободных macos-15 arm64, а macos-14 — тоже arm64, но другая очередь
arm = copy.deepcopy(mac)
arm['strategy']['matrix']['job'] = [dict(m, os='${{ inputs.runner }}') for m in arm['strategy']['matrix']['job'] if m['arch'] == 'aarch64']
wf_arm = {
    'name': 'Сборка qubeDesk — Mac Apple',
    'on': {'workflow_dispatch': {'inputs': {
        'upload-artifact': {'type': 'boolean', 'default': True, 'description': 'Собрать установщик'},
        'runner': {'type': 'string', 'default': 'macos-14', 'description': 'Машина GitHub (arm64)'}}}},
    'env': env,
    'jobs': {'generate-bridge': copy.deepcopy(bridge), 'build-for-macOS': arm},
}

# Сборка на своём Mac с Apple M1–M4 (помощник GitHub на компьютере владельца).
# Там нет sudo без пароля и wget, CocoaPods может не быть — шаги под это поправлены.
own = copy.deepcopy(arm)
own['runs-on'] = ['self-hosted', 'macOS', 'ARM64']
own['strategy']['matrix']['job'] = [{k: v for k, v in m.items() if k != 'os'} for m in arm['strategy']['matrix']['job']]
own['timeout-minutes'] = 360
for st in own['steps']:
    if st.get('name') == 'Install NASM':
        st['run'] = ('set -e\nD="$RUNNER_TEMP/nasm"; rm -rf "$D"; mkdir -p "$D"; cd "$D"\n'
                     'curl -fsSLO https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/macosx/nasm-2.16.03-macosx.zip\n'
                     'unzip -q nasm-2.16.03-macosx.zip\necho "$D/nasm-2.16.03" >> "$GITHUB_PATH"\n'
                     '"$D/nasm-2.16.03/nasm" --version || echo "NASM не запустился (нет Rosetta) — для arm64 он не нужен"\n')
assert any(st.get('name') == 'Install NASM' for st in own['steps'])
own['steps'].insert(0, {'name': 'qubeDesk: проверить Mac', 'shell': 'bash', 'run':
    'set -e\ncommand -v brew >/dev/null || { echo "Нужен Homebrew: https://brew.sh"; exit 1; }\n'
    'xcodebuild -version || { echo "Нужен Xcode из App Store и: sudo xcode-select -s /Applications/Xcode.app"; exit 1; }\n'
    'command -v pod >/dev/null || brew install cocoapods\ncommand -v python3\ndf -h "$GITHUB_WORKSPACE" | tail -1\n'})
wf_own = {
    'name': 'Сборка qubeDesk — на своём Mac',
    'on': {'workflow_dispatch': {'inputs': {
        'upload-artifact': {'type': 'boolean', 'default': True, 'description': 'Собрать установщик'}}}},
    'env': env,
    'jobs': {'generate-bridge': copy.deepcopy(bridge), 'build-for-macOS': own},
}

head = '# Создано .github/scripts/make-qubedesk-workflow.py — правьте сценарий, а не этот файл\n'
out = yaml.safe_dump(wf, allow_unicode=True, sort_keys=False, width=1000)
(root / 'workflows/qubedesk.yml').write_text(head + out)
(root / 'workflows/qubedesk-mac-arm.yml').write_text(head + yaml.safe_dump(wf_arm, allow_unicode=True, sort_keys=False, width=1000))
(root / 'workflows/qubedesk-mac-own.yml').write_text(head + yaml.safe_dump(wf_own, allow_unicode=True, sort_keys=False, width=1000))
print('готово:', root / 'workflows/qubedesk.yml', root / 'workflows/qubedesk-mac-arm.yml')
