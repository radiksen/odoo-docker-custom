# Odoo 18 Docker Custom Setup

A customized Docker environment for deploying Odoo 18 with a custom addons path and Caddy for automatic HTTPS.

## Features

- **Dockerized Odoo 18**: Runs the latest Odoo 18 Community Edition.
- **PostgreSQL Database**: Uses a PostgreSQL container for the database.
- **Custom Addons**: Includes a volume mount for your custom Odoo addons.
- **Caddy Webserver**: Acts as a reverse proxy and automatically provisions and renews SSL/TLS certificates (Let's Encrypt).
- **Persistent Data**: Uses Docker volumes to persist Odoo and database data.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/radiksen/odoo18-docker-custom.git](https://github.com/radiksen/odoo18-docker-custom.git)
    cd odoo18-docker-custom
    ```

2.  **Configure your environment:**
    Copy the example environment file and customize it to your needs.
    ```bash
    cp .env.example .env
    ```
    Now, open the `.env` file and set your `ODOO_MASTER_PASSWORD`, `DOMAIN`, `EMAIL`, and other variables.

3.  **Place your custom addons:**
    Put your custom Odoo addons inside the `./addons` directory.

## Usage

1.  **Start the services:**
    Run the following command to build and start all containers in the background:
    ```bash
    docker-compose up -d
    ```

2.  **Access Odoo:**
    Open your web browser and navigate to the domain you specified in the `.env` file (e.g., `https://odoo.your-domain.com`). Thanks to Caddy, HTTPS should be working automatically.

3.  **View logs:**
    To see the logs from all services, run:
    ```bash
    docker-compose logs -f
    ```
    To view logs for a specific service (e.g., odoo):
    ```bash
    docker-compose logs -f odoo
    ```

4.  **Stop the services:**
    To stop all running containers:
    ```bash
    docker-compose down
    ```

## Configuration

The main configuration is handled through the `.env` file, which is based on `.env.example`:

- `ODOO_MASTER_PASSWORD`: The master password for creating and managing Odoo databases. **Set a strong, secure password.**
- `DOMAIN`: Your public domain name for Odoo. Caddy will use this to get an SSL certificate.
- `EMAIL`: Your email address, used by Let's Encrypt for certificate notifications.
- `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`: PostgreSQL connection details.
- `ODOO_VERSION`: The Odoo version to use (e.g., `18.0`).
