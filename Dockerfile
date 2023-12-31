# AlmaLinux 8, Apache, PHP Dockerfile.

# Install AlmaLinux 8.
FROM almalinux:8

# Update Centos 8 and install Apache and PHP 7.4.
RUN dnf update -y \
&& dnf install -y vim bash unzip httpd php php-{fpm,cli,gd,pdo,xml,mbstring,zip,mysqlnd,opcache,json,intl,process} \
&& dnf module -y reset php \
&& dnf module -y enable php:7.4 \
&& dnf update -y \
&& dnf module -y install nodejs:16

# Copy application files and scripts usefull for Dockerfile.
COPY ./materials-browser.zip .
COPY ./docker-assets/materials-browser_p80.conf /etc/httpd/conf.d
COPY ./docker-assets/docker-services.sh /
COPY ./docker-assets/wait-for-it.sh /

# Declare argument coming from .env file.
ARG API_ADDRESS
ARG MYSQL_USER
ARG MYSQL_PASSWORD
ARG MYSQL_DATABASE
ARG SYMFONY_APP_ENV
ARG SYMFONY_APP_DEBUG

# Install application files and configure installation.
RUN unzip materials-browser.zip -d /var/www/html/materials-browser \
&& chown -R apache:apache /var/www/html/materials-browser \
&& mkdir /run/php-fpm \
&& chmod a+x /docker-services.sh \
&& chmod a+x /wait-for-it.sh \
&& sed -i "s|http://localhost:8000|${API_ADDRESS}|g" /var/www/html/materials-browser/assets/environment.json \
&& echo DATABASE_URL=mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@127.0.0.1:3306/${MYSQL_DATABASE}?serverVersion=5.5 > /var/www/html/materials-browser/api/.env.local \
&& echo APP_ENV=${SYMFONY_APP_ENV} >> /var/www/html/materials-browser/api/.env.local \
&& echo APP_DEBUG=${SYMFONY_APP_DEBUG} >> /var/www/html/materials-browser/api/.env.local

# Open HTTP and HTTPS port.
EXPOSE 80 443

# Change workdir to root of api part of project.
WORKDIR /var/www/html/materials-browser/api

# Run Bash script which start all necessaries services.
RUN echo "ServerName materials.fairsfair.charminghat.nl" >> /etc/httpd/apache2.conf
RUN npm install -g @angular/cli
CMD ["/docker-services.sh"]
