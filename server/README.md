# Сервер qubeDesk

Основа — открытый [rustdesk-server](https://github.com/rustdesk/rustdesk-server)
(AGPL-3.0), коммит `680b60395ecf99a76f74a1d934e453bb6e5e0aa2`. Наши правки — `qubedesk-hbbs.patch`:

- **обмен ключами на TCP** — сервер первым шлёт временный ключ, подписанный
  ключом сервера; дальше канал между программой и сервером зашифрован.
  Без него программа после входа через qubeOS не могла подключиться;
- **права на подключение** — пропуск из запроса уходит в qubeOS, и та решает,
  можно ли этому человеку к этому компьютеру. Компьютеры, привязанные к
  подразделению, — только тем, кто видит это подразделение. Отказ пишется в
  журнал точки.

Сборка:

    git clone --recurse-submodules https://github.com/rustdesk/rustdesk-server.git
    cd rustdesk-server && git checkout 680b60395ecf99a76f74a1d934e453bb6e5e0aa2 && git apply ../qubedesk-hbbs.patch
    cargo build --release --bin hbbs

Переменные: `QUBEDESK_ACCESS_URL` (адрес проверки в qubeOS) и
`QUBEDESK_SECRET` (общий секрет). Без них проверка прав выключена.
