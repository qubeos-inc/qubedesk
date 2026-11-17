# Наш hbbs: открытый сервер RustDesk + обмен ключами и проверка прав через qubeOS.
# Исходники — ../src (форк rustdesk-server, правки в src/qubedesk.rs).
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
COPY hbbs /usr/bin/hbbs
WORKDIR /root
