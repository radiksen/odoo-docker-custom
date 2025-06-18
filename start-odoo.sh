#!/bin/bash
set -e

read -p "Domain (e.g., example.com): " YOUR_DOMAIN
read -p "Email for Let's Encrypt: " YOUR_EMAIL
read -p "Odoo DB password (Postgres): " ODOO_DB_PASSWORD
read -p "Odoo master password: " ODOO_MASTER_PASSWORD

# .env
cat > .env <<EOF
YOUR_DOMAIN=${YOUR_DOMAIN}
ODOO_DB_PASSWORD=${ODOO_DB_PASSWORD}
POSTGRES_PASSWORD=${ODOO_DB_PASSWORD}
EOF

# odoo.conf
mkdir -p config
cat > config/odoo.conf <<EOF
[options]
admin_passwd = ${ODOO_MASTER_PASSWORD}

db_host = db
db_port = 5432
db_user = odoo
db_password = ${ODOO_DB_PASSWORD}

addons_path = /mnt/extra-addons

proxy_mode = True
EOF

# nginx
mkdir -p nginx
if [ ! -f nginx/default.conf.template ]; then
  cp nginx/default.conf nginx/default.conf.template
fi
envsubst '\$YOUR_DOMAIN' < nginx/default.conf.template > nginx/default.conf

# Запуск всех сервисов
docker-compose down -v
docker-compose up -d --build

# Подождать и остановить nginx
sleep 10
docker-compose stop nginx

# Получить сертификаты
docker-compose run --rm certbot certonly \
  --webroot -w /var/www/certbot \
  --email "${YOUR_EMAIL}" \
  --agree-tos \
  --no-eff-email \
  -d "${YOUR_DOMAIN}"

# Поднять всё
docker-compose up -d

echo "Done! Odoo: https://${YOUR_DOMAIN}"
