#!/bin/bash
set -e

echo "------------------------------"
echo "     Odoo 18 Setup Script     "
echo "------------------------------"

# --- Collect user input ---
read -p "🌐 Enter your domain (e.g., example.com): " YOUR_DOMAIN
read -p "📧 Enter email for Let's Encrypt: " YOUR_EMAIL
read -p "🔐 Enter PostgreSQL password for Odoo: " ODOO_DB_PASSWORD
read -p "🛡️  Enter Odoo master password: " ODOO_MASTER_PASSWORD

# --- Check for empty values ---
if [[ -z "$YOUR_DOMAIN" || -z "$YOUR_EMAIL" || -z "$ODOO_DB_PASSWORD" || -z "$ODOO_MASTER_PASSWORD" ]]; then
  echo "❌ All fields are required. Exiting."
  exit 1
fi

# --- Create .env file with environment variables ---
echo "📄 Creating .env file..."
cat > .env <<EOF
YOUR_DOMAIN=${YOUR_DOMAIN}
ODOO_DB_PASSWORD=${ODOO_DB_PASSWORD}
POSTGRES_PASSWORD=${ODOO_DB_PASSWORD}
EOF

# --- Generate Odoo configuration file ---
echo "⚙️  Generating config/odoo.conf..."
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

# --- Generate Nginx config from template ---
echo "🧩 Preparing Nginx config..."
mkdir -p nginx
if [ ! -f nginx/default.conf.template ]; then
  echo "⚠️  Template nginx/default.conf.template not found. Copying current default.conf as template..."
  cp nginx/default.conf nginx/default.conf.template
fi
envsubst '\$YOUR_DOMAIN' < nginx/default.conf.template > nginx/default.conf

# --- Start initial containers (Odoo, DB, Nginx) ---
echo "🚀 Starting containers (initial phase)..."
docker-compose down -v
docker-compose up -d --build

# --- Wait and stop Nginx before requesting SSL ---
echo "⏳ Waiting for Nginx to fully start..."
sleep 10
echo "🛑 Stopping Nginx before Certbot..."
docker-compose stop nginx

# --- Request SSL certificate from Let's Encrypt ---
echo "🔒 Requesting SSL certificate from Let's Encrypt..."
docker-compose run --rm certbot certonly \
  --webroot -w /var/www/certbot \
  --email "${YOUR_EMAIL}" \
  --agree-tos \
  --no-eff-email \
  -d "${YOUR_DOMAIN}"

# --- Restart all services with SSL in place ---
echo "🔁 Restarting all containers with SSL enabled..."
docker-compose up -d

# --- Done ---
echo "✅ Setup complete!"
echo "🌍 Your Odoo is available at: https://${YOUR_DOMAIN}"
echo "🔄 Certbot will automatically renew SSL certificates."
