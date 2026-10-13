#!/bin/sh
set -e

DB_PASS="$(cat /run/secrets/db_password)"
WP_ADMIN_PASS="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASS="$(cat /run/secrets/wp_user_password)"

cd /var/www/html

# MariaDB가 TCP 연결을 받을 때까지 대기 (준비되면 종료되는 루프)
until mariadb-admin ping -h mariadb -u"${MYSQL_USER}" -p"${DB_PASS}" --silent 2> /dev/null; do
    sleep 2
done

# 최초 1회만 WordPress 설치
if [ ! -f wp-config.php ]; then
    wp core download --allow-root

    wp config create --allow-root \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASS}" \
        --dbhost=mariadb

    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASS}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email

    wp user create "${WP_USER}" "${WP_USER_EMAIL}" --allow-root \
        --user_pass="${WP_USER_PASS}" \
        --role=author
fi

chown -R www-data:www-data /var/www/html

# php-fpm을 foreground, PID 1로 실행
exec php-fpm8.2 -F
