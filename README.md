# wildcardsh

Скрипт для автоматизированного пакетного выпуска Wildcard-сертификатов Let's Encrypt (`*.example.com` и `example.com`) с помощью клиента `acme.sh` и DNS-01 валидации через Cloudflare API.

## Особенности

* 📦 **Поддержка нескольких доменов:** Выпуск сертификатов для любого количества доменов за один запуск.
* ⚡ **Автоматизация под ключ:** Сам проверяет и при необходимости устанавливает зависимости (`acme.sh`, `cron`, `socat`, `curl`).
* ☁️ **Cloudflare DNS-01:** Подтверждение владения доменом через API без необходимости настраивать веб-сервер, останавливать службы или открывать 80/443 порты.
* 🛡️ **Изолированная обработка:** Ошибка при валидации одного домена не прерывает выпуск для остальных.
* 🔒 **Безопасность:** Раскладывает сертификаты по изолированным папкам `/etc/ssl/<домен>/` с безопасными правами доступа (`600` на приватный ключ).
* 🔄 **Автопродление:** `acme.sh` регистрирует задачу в системном cron для фонового обновления сертификатов каждые 60 дней.

## Требования

* ОС Linux (Debian, Ubuntu, CentOS, Alpine и др.).
* Права суперпользователя (`root` или `sudo`).
* Домены, делегированные на DNS Cloudflare.
* API Token Cloudflare с правами **Zone - DNS - Edit** для нужных зон.

---

## Использование

> ⚠️ **Важно:** Первым аргументом передается **API токен Cloudflare**, а затем — один или несколько доменов через пробел или запятую.

### Быстрый запуск в одну команду (без клонирования)

**Для одного домена:**

```bash
curl -sL https://raw.githubusercontent.com/Revellison/wildcardsh/main/setup_wildcard.sh | sudo bash -s -- ВАШ_API_ТОКЕН_CLOUDFLARE example.com

```

**Для нескольких доменов (через пробел):**

```bash
curl -sL https://raw.githubusercontent.com/Revellison/wildcardsh/main/setup_wildcard.sh | sudo bash -s -- ВАШ_API_ТОКЕН_CLOUDFLARE first-domain.com second-domain.org third-domain.net

```

**Для нескольких доменов (через запятую):**

```bash
curl -sL https://raw.githubusercontent.com/Revellison/wildcardsh/main/setup_wildcard.sh | sudo bash -s -- ВАШ_API_ТОКЕН_CLOUDFLARE first-domain.com,second-domain.org,third-domain.net

```

---

### Запуск локального файла

Если скрипт сохранён локально (например, `setup_wildcard.sh` или `acme.sh`), передавать флаги `-s --` не нужно:

```bash
sudo bash ./setup_wildcard.sh ВАШ_API_ТОКЕН_CLOUDFLARE first-domain.com second-domain.org

```

---

## Расположение файлов

Для каждого успешно обработанного домена сертификаты монтируются в отдельный каталог:

```text
/etc/ssl/<домен>/
├── fullchain.pem   # Полная цепочка сертификатов (chmod 644 / 755 директория)
└── privkey.pem     # Приватный ключ (chmod 600)

```

Пример путей для `example.com`:

* **Приватный ключ:** `/etc/ssl/[example.com/privkey.pem](https://example.com/privkey.pem)`
* **Сертификат:** `/etc/ssl/[example.com/fullchain.pem](https://example.com/fullchain.pem)`

---

## Настройка Cloudflare API Token

1. Перейдите в **Cloudflare Dashboard** → **My Profile** → **API Tokens** → **Create Token**.
2. Используйте шаблон **Edit zone DNS** или создайте Custom Token со следующими правами:
* `Zone` — `DNS` — `Edit`
* `Zone` — `Zone` — `Read`


3. В поле **Zone Resources** укажите `Include` → `All zones` (или выберите конкретные домены).
