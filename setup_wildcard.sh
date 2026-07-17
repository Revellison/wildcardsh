#!/usr/bin/env bash

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Ошибка: Не указаны параметры!"
    echo "Использование: curl -sL <ССЫЛКА_RAW_НА_GITHUB> | sudo bash -s -- <ДОМЕН> <API_ТОКЕН_CLOUDFLARE>"
    exit 1
fi

DOMAIN="$1"
export CF_Token="$2"

if [ "$EUID" -ne 0 ]; then
  echo "Ошибка: Пожалуйста, запустите скрипт с правами root (добавьте sudo перед bash)"
  exit 1
fi

echo "=== 1. Установка acme.sh ==="
curl -sL https://get.acme.sh | sh -s email="admin@$DOMAIN"

ACME_SH="$HOME/.acme.sh/acme.sh"

echo "=== 2. Выпуск Wildcard сертификата для $DOMAIN ==="
$ACME_SH --issue --dns dns_cf \
  -d "$DOMAIN" \
  -d "*.$DOMAIN" \
  --server letsencrypt

echo "=== 3. Создание папки для сертификатов ==="
mkdir -p /etc/ssl/$DOMAIN
chmod 755 /etc/ssl/$DOMAIN

echo "=== 4. Установка ключей в рабочую папку ==="
$ACME_SH --install-cert -d "$DOMAIN" \
  --key-file       /etc/ssl/$DOMAIN/privkey.pem \
  --fullchain-file /etc/ssl/$DOMAIN/fullchain.pem

chmod 600 /etc/ssl/$DOMAIN/privkey.pem

echo "========================================================="
echo "УСПЕШНО! Сертификаты выпущены и настроены на автопродление."
echo "Путь к приватному ключу:   /etc/ssl/$DOMAIN/privkey.pem"
echo "Путь к полному сертификату: /etc/ssl/$DOMAIN/fullchain.pem"
echo "========================================================="
