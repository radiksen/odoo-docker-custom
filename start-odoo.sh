#!/bin/bash
set -e

# --- User input ---
read -p "Domain (e.g., example.com): " YOUR_DOMAIN
read -p "Email for Let's Encrypt: " YOUR_EMAIL
read -p "PostgreSQL password for Odoo: " ODOO_DB_PASSWORD
read -p "Odoo master password: " ODOO_MASTER_PASSWORD

# --- Check input ---
if [[ -z "$YOUR_DOMAIN" || -z "$YOUR_EMAIL" || -z "$ODOO_DB_PASSWORD" || -z "$ODOO_MASTER_PASSWORD" ]]; then
  echo "All fields are required. Exiting."
  exit 1
fi

# --- Create .env file ---
cat > .env <<EOF
YOUR_DOMAIN=${YOUR_DOMAIN}
ODOO_DB_PASSWORD=${ODOO_DB_PASSWORD}
POSTGRES_PASSWORD=${ODOO_DB_PASSWORD}
EOF

# --- Create Odoo config ---
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

# --- Generate Nginx config ---
mkdir -p nginx
if [ ! -f nginx/default.conf.template ]; then
  echo "Missing nginx/default.conf.template"
  exit 1
fi
if ! grep -q '\${YOUR_DOMAIN}' nginx/default.conf.template; then
  echo "Template must contain \${YOUR_DOMAIN}"
  exit 1
fi
envsubst '\$YOUR_DOMAIN' < nginx/default.conf.template > nginx/default.conf

# --- Start services ---
docker-compose down -v
docker-compose up -d --build

# --- Stop Nginx for certbot ---
sleep 10
docker-compose stop nginx

# --- Run certbot ---
docker-compose run --rm certbot certonly \
  --webroot -w /var/www/certbot \
  --email "${YOUR_EMAIL}" \
  --agree-tos \
  --no-eff-email \
  -d "${YOUR_DOMAIN}"

# --- Restart all ---
docker-compose up -d

echo "Done. Odoo is running at https://${YOUR_DOMAIN}"
