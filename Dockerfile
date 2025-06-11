# Используем официальный образ Odoo 18 в качестве базового
FROM odoo:18.0

# Копируем ваш файл конфигурации odoo.conf в образ
# Предполагаем, что config/odoo.conf находится в вашем репозитории
COPY ./config/odoo.conf /etc/odoo/odoo.conf

# Копируем ваши кастомные модули в образ
# Предполагаем, что папка custom_addons находится в вашем репозитории
COPY ./custom_addons /mnt/extra-addons/custom_addons

# Если у вас есть дополнительные Python-зависимости,
# создайте файл requirements.txt в корне репозитория и раскомментируйте следующие строки:
# COPY requirements.txt /tmp/requirements.txt
# RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Устанавливаем пользователя для запуска Odoo внутри контейнера
USER odoo

# Указываем путь к файлу конфигурации Odoo
ENV ODOO_CONF=/etc/odoo/odoo.conf
