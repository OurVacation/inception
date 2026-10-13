# 사용자 문서

> 이 문서는 [USER_DOC.md](USER_DOC.md)의 한국어 번역본입니다.

## 제공되는 서비스

| 서비스 | 목적 | 접근 방법 |
|---|---|---|
| **nginx** | 스택의 HTTPS 진입점 | `https://taewonki.42.fr` (443 포트) |
| **wordpress** | WordPress 웹사이트 (php-fpm) | nginx를 통해 접근 |
| **mariadb** | WordPress가 사용하는 데이터베이스 | 내부 전용, 외부에서 접근 불가 |

## 프로젝트 시작과 중지

저장소 루트에서 아래 명령을 실행합니다.

| 동작 | 명령 |
|---|---|
| 빌드 후 시작 | `make` |
| 중지 (컨테이너 유지) | `make stop` |
| 다시 시작 | `make start` |
| 중지하고 컨테이너 삭제 | `make down` |
| 전체 정리 (컨테이너, 이미지, 볼륨, 데이터) | `make fclean` |

> `make fclean`은 `/home/taewonki/data`에 있는 웹사이트와 데이터베이스 데이터를 모두 삭제합니다.

## 웹사이트와 관리자 페이지 접속

1. `/etc/hosts`에 `127.0.0.1 taewonki.42.fr`이 있는지 확인합니다.
2. 웹사이트: `https://taewonki.42.fr`에 접속합니다.
3. 관리자 페이지: `https://taewonki.42.fr/wp-admin`에 접속합니다.

TLS 인증서가 자체 서명이라 브라우저에 보안 경고가 뜹니다. 계속 진행을 선택하세요.

80 포트의 일반 HTTP는 제공되지 않습니다.

## 자격증명 위치와 관리

비밀번호는 저장소 루트의 `secrets/` 폴더에 파일로 저장돼 있으며, git에는 저장되지 않습니다.

| 파일 | 용도 |
|---|---|
| `secrets/db_password.txt` | WordPress 데이터베이스 사용자 비밀번호 |
| `secrets/db_root_password.txt` | MariaDB root 사용자 비밀번호 |
| `secrets/wp_admin_password.txt` | WordPress 관리자 비밀번호 |
| `secrets/wp_user_password.txt` | 두 번째 WordPress 사용자 비밀번호 |

민감하지 않은 값(도메인, DB 이름, 사용자 이름, 이메일)은 `srcs/.env`에 있습니다.

비밀번호 확인: `cat secrets/wp_admin_password.txt`

> 데이터베이스와 WordPress 계정은 최초 시작 때만 생성됩니다. 이후 비밀번호 파일을 바꿨다면 `make fclean` 후 `make`를 실행해서 새 값으로 계정을 다시 만들어야 합니다.

## 서비스가 정상 동작하는지 확인

1. 컨테이너 목록을 확인합니다. `mariadb`, `wordpress`, `nginx`가 모두 `Up`이어야 합니다.
   ```
   make ps
   ```
2. HTTPS로 웹사이트가 응답하는지 확인합니다.
   ```
   curl -k -I https://taewonki.42.fr
   ```
3. 문제가 있으면 로그를 확인합니다.
   ```
   docker logs mariadb
   docker logs wordpress
   docker logs nginx
   ```
4. `srcs/.env`에 정의된 관리자 계정(`WP_ADMIN_USER`)으로 `https://taewonki.42.fr/wp-admin`에 로그인합니다.
