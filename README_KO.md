*이 프로젝트는 42 커리큘럼의 일부로 taewonki가 작성했습니다.*

> 이 문서는 [README.md](README.md)의 한국어 번역본입니다.

# Inception

## 설명

Inception은 42 커리큘럼의 시스템 관리 프로젝트입니다. 목표는 Docker로 작은 웹 인프라를 구축하는 것이며, 모든 서비스는 직접 작성한 Dockerfile로 빌드한 컨테이너에서 실행됩니다.

스택은 세 가지 서비스로 구성됩니다.

| 서비스 | 역할 |
|---|---|
| **nginx** | 유일한 진입점입니다. 443 포트만 열고, TLSv1.2/1.3만 허용하며, 자체 서명 인증서를 사용합니다. PHP 요청을 WordPress로 전달합니다. |
| **wordpress** | WordPress와 php-fpm(9000 포트)입니다. 내부에 웹 서버는 없습니다. WP-CLI로 설치하고 설정합니다. |
| **mariadb** | WordPress용 MariaDB 데이터베이스(3306 포트)이며, Docker 네트워크 안에서만 접근할 수 있습니다. |

모든 것은 가상 머신 안에서 실행되고 `docker compose`로 관리됩니다. 컨테이너는 `debian:bookworm`(작성 시점 기준 Debian의 penultimate stable 버전)으로 빌드합니다. 완성된 이미지(nginx, wordpress, mariadb)는 pull하지 않습니다.

### 프로젝트 구조

```
.
├── Makefile
├── secrets/                  # 비밀번호 (git에서 제외)
└── srcs/
    ├── .env                  # 민감하지 않은 변수 (git에서 제외)
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/   (Dockerfile, conf/, tools/)
        ├── nginx/     (Dockerfile, conf/, tools/)
        └── wordpress/ (Dockerfile, conf/, tools/)
```

### 설계 선택

- **컨테이너당 하나의 프로세스.** 각 데몬은 foreground로 PID 1이 되어 실행됩니다(`exec mariadbd`, `exec php-fpm8.2 -F`, `nginx -g "daemon off;"`). 컨테이너를 유지하려고 `tail -f`, `sleep infinity`, 무한 루프를 쓰지 않습니다.
- **초기화 스크립트는 멱등합니다.** MariaDB와 WordPress는 최초 시작 때만 설정되므로, 스택을 재시작해도 데이터가 유지됩니다.
- **비밀번호는 Dockerfile, compose 파일, 저장소 어디에도 없습니다.** 실행 시점에 Docker secrets에서 읽습니다.
- **호스트에는 443 포트만 공개합니다.**

### 비교

**가상 머신 vs Docker.** 가상 머신은 하드웨어 전체를 에뮬레이션하고 자체 커널과 운영체제를 실행하므로 무겁지만 격리 수준이 높습니다. Docker 컨테이너는 호스트 커널을 공유하고 프로세스, 파일시스템, 네트워크만 격리하므로 몇 초 만에 시작하고 자원을 훨씬 적게 씁니다. 이 프로젝트에서 VM은 호스트 환경이고, Docker는 그 안에서 서비스를 실행합니다.

**Secrets vs 환경변수.** 환경변수는 간단하지만 `docker inspect`, 프로세스 목록, 로그로 유출될 수 있습니다. Docker secrets는 `/run/secrets/` 아래에 읽기 전용 파일로 마운트되며 환경에 노출되지 않습니다. 이 프로젝트는 민감하지 않은 값(도메인, DB 이름, 사용자 이름)은 `.env`에, 비밀번호는 secrets에 둡니다.

**Docker Network vs Host Network.** 사용자 정의 bridge 네트워크에서는 컨테이너가 자신만의 격리된 네트워크를 가지며 서비스 이름으로 서로 접근합니다(예: `wordpress`가 `mariadb:3306`에 연결). 명시적으로 공개한 포트만 외부에서 접근할 수 있습니다. host 네트워크 모드는 이 격리를 없애고 호스트의 네트워크 스택을 공유하므로, 이 프로젝트에서는 금지돼 있습니다.

**Docker Volumes vs Bind Mounts.** named volume은 Docker가 관리하며 데이터를 영속화하는 권장 방식입니다. 바인드 마운트는 임의의 호스트 경로를 컨테이너에 직접 연결하므로 호스트의 디렉터리 구조에 의존합니다. 여기서 쓰는 두 영속 볼륨(`mariadb_data`, `wordpress_data`)은 named volume이며, 서브젝트 요구대로 local 드라이버 옵션을 사용해 데이터를 `/home/taewonki/data/`에 저장합니다.

## 사용 방법

사전 준비: Docker와 Docker Compose, `make`가 설치된 Debian/Ubuntu 가상 머신.

1. `/etc/hosts`에 도메인을 추가합니다.
   ```
   127.0.0.1 taewonki.42.fr
   ```
2. secrets를 만듭니다(git에 저장되지 않습니다). 전체 파일 목록은 [DEV_DOC_KO.md](DEV_DOC_KO.md)를 참고하세요.
3. `srcs/.env`를 만듭니다([DEV_DOC_KO.md](DEV_DOC_KO.md) 참고).
4. 전체를 빌드하고 시작합니다.
   ```
   make
   ```
5. 브라우저에서 `https://taewonki.42.fr`에 접속합니다(자체 서명 인증서 경고는 허용합니다).

주요 타겟: `make down`, `make stop`, `make start`, `make logs`, `make ps`, `make clean`, `make fclean`, `make re`.

추가 문서:
- [USER_DOC_KO.md](USER_DOC_KO.md): 사용자와 관리자용
- [DEV_DOC_KO.md](DEV_DOC_KO.md): 개발자용

## 참고 자료

- Docker 문서: https://docs.docker.com/
- Docker Compose 파일 레퍼런스: https://docs.docker.com/compose/compose-file/
- Dockerfile 모범 사례: https://docs.docker.com/build/building/best-practices/
- NGINX 문서: https://nginx.org/en/docs/
- MariaDB 문서: https://mariadb.com/kb/en/documentation/
- WP-CLI 핸드북: https://make.wordpress.org/cli/handbook/
- PHP-FPM 설정: https://www.php.net/manual/en/install.fpm.configuration.php

### AI 사용

AI는 다음 작업의 보조 도구로 사용했습니다.
- 서브젝트 요구사항 조사와 요약
- Dockerfile, 설정 파일, entrypoint 스크립트, Makefile, compose 파일의 초안 작성
- 문서 초안 작성
- PID 1, Docker secrets, 드라이버 옵션을 쓰는 named volume 같은 개념 설명

생성된 모든 내용은 검토하고 가상 머신에서 테스트했으며, 작성자가 이해하고 설명할 수 있습니다.
