#!/usr/bin/env bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Ошибка: Запустите скрипт с правами root (sudo bash ...)"
  exit 1
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    -s|--) shift ;;
    *) break ;;
  esac
done

if [ "$#" -lt 2 ]; then
  echo "Ошибка: Не указаны параметры!"
  echo "Использование: sudo bash $0 <ТОКЕН_CLOUDFLARE> <ДОМЕН_1> [ДОМЕН_2] ..."
  exit 1
fi

export CF_Token="$1"
shift

DOMAINS=()
for arg in "$@"; do
  [ "$arg" = "--" ] && continue
  for d in ${arg//,/ }; do
    [ -n "$d" ] && DOMAINS+=("$d")
  done
done

if [ ${#DOMAINS[@]} -eq 0 ]; then
  echo "Ошибка: Не передано ни одного домена!"
  exit 1
fi

PRIMARY_DOMAIN="${DOMAINS[0]}"
EMAIL="admin@${PRIMARY_DOMAIN}"
ACME_SH="$HOME/.acme.sh/acme.sh"

echo "=== 1. Подготовка acme.sh и аккаунта Let's Encrypt ==="
if [ ! -f "$ACME_SH" ]; then
  curl -sL https://get.acme.sh | sh -s email="$EMAIL"
fi

if [ -f "$HOME/.acme.sh/account.conf" ]; then
  if grep -q "ACCOUNT_EMAIL=" "$HOME/.acme.sh/account.conf"; then
    sed -i "s/ACCOUNT_EMAIL=.*/ACCOUNT_EMAIL='$EMAIL'/" "$HOME/.acme.sh/account.conf"
  else
    echo "ACCOUNT_EMAIL='$EMAIL'" >> "$HOME/.acme.sh/account.conf"
  fi
fi

"$ACME_SH" --register-account -m "$EMAIL" --server letsencrypt 2>/dev/null || true

SUCCESS=()
FAILED=()

echo "=== 2. Выпуск сертификатов для ${#DOMAINS[@]} домен(ов) ==="

for DOMAIN in "${DOMAINS[@]}"; do
  echo "---------------------------------------------------------"
  echo "Обработка: $DOMAIN (*.$DOMAIN)"
  echo "---------------------------------------------------------"

  if "$ACME_SH" --issue --dns dns_cf \
    -d "$DOMAIN" \
    -d "*.$DOMAIN" \
    --server letsencrypt; then

    mkdir -p "/etc/ssl/$DOMAIN"
    chmod 755 "/etc/ssl/$DOMAIN"

    "$ACME_SH" --install-cert -d "$DOMAIN" \
      --key-file       "/etc/ssl/$DOMAIN/privkey.pem" \
      --fullchain-file "/etc/ssl/$DOMAIN/fullchain.pem"

    chmod 600 "/etc/ssl/$DOMAIN/privkey.pem"
    SUCCESS+=("$DOMAIN")
  else
    echo "[-] Ошибка при выпуске сертификата для $DOMAIN" >&2
    FAILED+=("$DOMAIN")
  fi
done

echo "========================================================="
echo "ИТОГИ ОБРАБОТКИ:"

if [ ${#SUCCESS[@]} -gt 0 ]; then
  echo "Успешно настроены (${#SUCCESS[@]}):"
  for d in "${SUCCESS[@]}"; do
    echo "  [+] $d"
    echo "      Ключ:        /etc/ssl/$d/privkey.pem"
    echo "      Сертификат:  /etc/ssl/$d/fullchain.pem"
  done
fi

if [ ${#FAILED[@]} -gt 0 ]; then
  echo ""
  echo "Ошибки выпуска (${#FAILED[@]}):"
  for d in "${FAILED[@]}"; do
    echo "  [-] $d"
  done
  exit 1
fi
echo "========================================================="
