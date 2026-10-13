#!/bin/sh
set -e

DB_PASS="$(cat /run/secrets/db_password)"
ROOT_PASS="$(cat /run/secrets/db_root_password)"

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# 1) 데이터 디렉터리가 비어 있으면 시스템 테이블 초기화
if [ ! -d /var/lib/mysql/mysql ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

# 2) WordPress DB가 없으면 임시 서버(네트워크 비활성)로 최초 1회 설정
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    mariadbd --user=mysql --skip-networking &
    pid=$!

    # 서버가 준비될 때까지 대기 (준비되면 종료되는 대기 루프)
    until mariadb-admin ping --silent 2> /dev/null; do
        sleep 1
    done

    mariadb <<SQL
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}';
FLUSH PRIVILEGES;
SQL

    mariadb-admin -uroot -p"${ROOT_PASS}" shutdown
    wait "$pid"
fi

# 3) 진짜 서버를 PID 1로 실행 (foreground)
exec mariadbd --user=mysql
