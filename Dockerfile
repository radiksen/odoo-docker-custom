# Use the official Odoo 18 image as a base
FROM odoo:18.0

# Copy your custom addons into the image
# Assumes a 'custom_addons' folder exists in your repository root
COPY ./custom_addons /mnt/extra-addons/custom_addons

# If you have additional Python dependencies,
# create a requirements.txt file in the repository root and uncomment the following lines:
# COPY requirements.txt /tmp/requirements.txt
# RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Set the user to run Odoo inside the container
USER odoo

# Specify the path to the Odoo configuration file
ENV ODOO_CONF=/etc/odoo/odoo.conf
