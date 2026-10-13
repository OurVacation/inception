# 개발자 문서

> 이 문서는 [DEV_DOC.md](DEV_DOC.md)의 한국어 번역본입니다.

## 환경을 처음부터 구성하기

### 사전 준비

- Debian 또는 Ubuntu가 설치된 가상 머신
- `git`, `make`, `openssl`
- Docker Engine과 Docker Compose 플러그인(`docker compose`)
- 사용자가 `docker` 그룹에 속해 있어야 합니다(`usermod -aG docker <user>` 후 로그아웃과 재로그인).

### 도메인 이름

도메인이 로컬 머신을 가리키게 합니다.

```
echo "127.0.0.1 taewonki.42.fr" | sudo tee -a /etc/hosts
```

### 설정 파일

저장소를 clone한 뒤, git에 없는 두 가지를 만듭니다.

**1. `srcs/.env`** (민감하지 않은 값만):

```
DOMAIN_NAME=taewonki.42.fr

# MYSQL SETUP
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

# WORDPRESS SETUP
WP_TITLE=Inception
WP_ADMIN_USER=<관리자 이름, "admin"이나 "administrator"가 포함되면 안 됨>
WP_ADMIN_EMAIL=<이메일>
WP_USER=<두 번째 사용자 이름>
WP_USER_EMAIL=<이메일>
```

**2. `secrets/`** (비밀번호마다 파일 하나, 파일에는 비밀번호만 넣습니다):

```
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

`secrets/`와 `srcs/.env`는 `.gitignore`에 들어 있습니다. 절대 커밋하지 마세요.

`mariadb/tools/init.sh`가 비밀번호를 SQL 문에 넣기 때문에, 비밀번호에 작은따옴표와 백틱은 쓰지 마세요.

## 프로젝트 빌드와 실행

Makefile은 `docker compose -f srcs/docker-compose.yml`을 감쌉니다.

| 명령 | 동작 |
|---|---|
| `make` | `/home/taewonki/data/{mariadb,wordpress}`를 만들고, 이미지를 빌드하고, 스택을 백그라운드로 시작 |
| `make down` | 컨테이너와 네트워크를 중지하고 삭제 (볼륨과 데이터는 유지) |
| `make stop` / `make start` | 기존 컨테이너를 중지 / 시작 |
| `make logs` | 모든 서비스의 로그를 따라가며 출력 |
| `make ps` | 컨테이너 상태 표시 |
| `make clean` | `make down` 후 사용하지 않는 Docker 객체를 정리 |
| `make fclean` | 컨테이너, 이미지, 볼륨, `/home/taewonki/data`를 삭제 |
| `make re` | `make fclean` 후 `make` |

## 컨테이너와 볼륨 관리

```
docker compose -f srcs/docker-compose.yml ps
docker exec -it wordpress sh          # 컨테이너 안 셸
docker logs <container>               # 컨테이너 하나의 로그
docker volume ls                      # 볼륨 목록
docker volume inspect mariadb_data wordpress_data
docker network ls                     # "inception" 네트워크
docker top <container>                # 프로세스 (PID 1이 데몬)
```

WordPress 사용자 확인:

```
docker exec wordpress wp user list --allow-root --path=/var/www/html
```

## 데이터 저장 위치와 영속성

두 named volume은 `srcs/docker-compose.yml`에서 `local` 드라이버와, 데이터를 호스트에 두는 옵션으로 선언돼 있습니다.

| 볼륨 | 컨테이너 경로 | 호스트 경로 |
|---|---|---|
| `mariadb_data` | `/var/lib/mysql` | `/home/taewonki/data/mariadb` |
| `wordpress_data` | `/var/www/html` | `/home/taewonki/data/wordpress` |

데이터가 호스트에 있으므로 `make down`, 컨테이너 재시작, 재빌드를 거쳐도 유지됩니다. `make fclean`으로만 삭제됩니다.

entrypoint 스크립트는 시작할 때마다 볼륨 내용을 확인합니다.
- `mariadb/tools/init.sh`는 시스템 테이블을 초기화하고 데이터베이스와 사용자를 아직 없을 때만 만든 뒤, `mariadbd`를 PID 1로 실행합니다.
- `wordpress/tools/setup.sh`는 MariaDB를 기다리고, `wp-config.php`가 없을 때만 WP-CLI로 WordPress를 내려받아 설치한 뒤, `php-fpm8.2 -F`를 PID 1로 실행합니다.

### secrets 전달 방식

`docker-compose.yml`이 `secrets/`의 파일을 `secrets:` 키로 선언하고, 각 서비스는 필요한 secret만 나열합니다. 컨테이너 안에서는 `/run/secrets/<이름>` 파일로 나타나며, 스크립트가 실행 시점에 읽습니다.

| Secret | mariadb | wordpress |
|---|---|---|
| `db_password` | 예 | 예 |
| `db_root_password` | 예 | 아니오 |
| `wp_admin_password` | 아니오 | 예 |
| `wp_user_password` | 아니오 | 예 |

### 서비스

| 서비스 | 이미지 | 비고 |
|---|---|---|
| `nginx` | `debian:bookworm`으로 빌드 | 빌드 시 자체 서명 인증서 생성, TLSv1.2/1.3, 443 포트 공개 |
| `wordpress` | `debian:bookworm`으로 빌드 | 9000 포트의 php-fpm, WP-CLI |
| `mariadb` | `debian:bookworm`으로 빌드 | 3306 포트는 내부 네트워크에서만 사용 |

모든 컨테이너는 `restart: always`를 사용하며 `inception` bridge 네트워크에 연결됩니다.
