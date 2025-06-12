#!/bin/bash

# --- Скрипт для универсального развертывания Odoo с Docker Compose и Let's Encrypt ---

echo "--- Начало настройки Odoo ---"

# --- 1. Запрос переменных от пользователя ---
read -p "Введите ваш домен (например, example.com): " YOUR_DOMAIN
read -p "Введите ваш email для Let's Encrypt: " YOUR_EMAIL
read -p "Введите надежный пароль для базы данных Odoo: " ODOO_DB_PASSWORD
read -p "Введите надежный мастер-пароль для Odoo: " ODOO_MASTER_PASSWORD

# Простая проверка на пустые значения
if [ -z "$YOUR_DOMAIN" ] || [ -z "$YOUR_EMAIL" ] || [ -z "$ODOO_DB_PASSWORD" ] || [ -z "$ODOO_MASTER_PASSWORD" ]; then
  echo "Ошибка: Все поля обязательны для заполнения. Пожалуйста, попробуйте снова."
  exit 1
fi

# --- 2. Создание файла .env ---
# Этот файл будет содержать переменные окружения для docker-compose
echo "Создаем файл .env с вашими настройками..."
echo "YOUR_DOMAIN=${YOUR_DOMAIN}" > .env
echo "YOUR_EMAIL=${YOUR_EMAIL}" >> .env
echo "ODOO_DB_PASSWORD=${ODOO_DB_PASSWORD}" >> .env
echo "ODOO_MASTER_PASSWORD=${ODOO_MASTER_PASSWORD}" >> .env # Это не используется напрямую в Docker Compose, но полезно сохранить

echo ".env файл создан."

# --- 3. Подготовка конфигурации Odoo (odoo.conf) ---
# Odoo.conf уже скопирован в Dockerfile, но если вы хотите,
# чтобы odoo.conf был динамическим или монтировался, это место для его генерации.
# Для текущей настройки, где odoo.conf уже в образе, этот шаг не критичен для его содержимого.
# Однако, master_password можно передать в odoo.conf только если он монтируется,
# либо можно задать его через ENV переменную в Dockerfile/docker-compose.yml.

echo "Создаем odoo.conf с вашими настройками..."
mkdir -p config # Убедимся, что папка config существует
echo "[options]" > config/odoo.conf
echo "admin_passwd = ${ODOO_MASTER_PASSWORD}" >> config/odoo.conf
echo "db_host = db" >> config/odoo.conf
echo "db_port = 5432" >> config/odoo.conf
echo "db_user = odoo" >> config/odoo.conf
echo "db_password = ${ODOO_DB_PASSWORD}" >> config/odoo.conf
echo "addons_path = /mnt/extra-addons" >> config/odoo.conf
echo "proxy_mode = True" >> config/odoo.conf



# --- 4. Подготовка конфигурации Nginx (динамически генерируем из шаблона) ---
# Мы используем envsubst для замены переменных в default.conf
echo "Генерируем конфигурацию Nginx из шаблона..."
mkdir -p nginx
envsubst < ./nginx/default.conf > ./nginx/default.conf.temp
mv ./nginx/default.conf.temp ./nginx/default.conf
# IMPORTANT: After running envsubst, the placeholders are replaced.
# The original file is modified, so if you commit this, make sure to revert it.
# For a persistent solution, keep default.conf as a template (e.g., default.conf.template)
# and always generate default.conf.

# --- 5. Запуск Docker Compose для сборки образа и начальных сервисов ---
echo "Запускаем Nginx, Odoo и базу данных..."
# --build обновит ваш пользовательский образ Odoo, если были изменения в Dockerfile
docker-compose up -d --build web db nginx

# --- 6. Ожидание запуска Nginx ---
echo "Ожидание запуска Nginx перед запросом сертификатов..."
sleep 15 # Даем контейнерам время запуститься

# --- 7. Остановка Nginx для Certbot (если он занял порт 80) ---
echo "Останавливаем Nginx для Certbot..."
docker-compose stop nginx

# --- 8. Запуск Certbot для получения сертификатов ---
echo "Запрашиваем SSL-сертификаты для $YOUR_DOMAIN..."
# certbot будет использовать переменные из .env
docker-compose run --rm \
  certbot certonly --webroot -w /var/www/certbot \
  --email "${YOUR_EMAIL}" \
  --agree-tos \
  --no-eff-email \
  -d "${YOUR_DOMAIN}"

if [ $? -ne 0 ]; then
    echo "--------------------------------------------------------------------------------"
    echo "ОШИБКА: Не удалось получить SSL-сертификаты."
    echo "Пожалуйста, проверьте следующее:"
    echo "1. Убедитесь, что ваш домен '${YOUR_DOMAIN}' корректно указывает на IP-адрес вашего сервера (A-запись)."
    echo "2. Убедитесь, что порты 80 и 443 открыты на вашем сервере и не заняты другими приложениями."
    echo "3. Проверьте правильность введенного email '${YOUR_EMAIL}'."
    echo "4. Попробуйте запустить скрипт еще раз. Иногда это временная проблема."
    echo "--------------------------------------------------------------------------------"
    exit 1
fi

# --- 9. Запуск всех сервисов (с Nginx и автоматическим обновлением Certbot) ---
echo "Сертификаты успешно получены. Запускаем все сервисы..."
docker-compose up -d

echo "--- Настройка Odoo завершена! ---"
echo "Ваш Odoo доступен по адресу: https://${YOUR_DOMAIN}"
echo "Certbot будет автоматически обновлять сертификаты."
echo "Вы можете удалить файл .env, если не хотите, чтобы пароли хранились на диске, но тогда вам придется вводить их при каждом запуске docker-compose."
echo "Однако, для удобства, обычно его оставляют."
