*This project has been created as part of the 42 curriculum by taewonki.*

# Inception

## Description

Inception is a system administration project from the 42 curriculum. The goal is to build a small web infrastructure with Docker, where every service runs in its own container built from a Dockerfile written by hand.

The stack is made of three services:

| Service | Role |
|---|---|
| **nginx** | The only entrypoint. Listens on port 443 only, TLSv1.2/1.3 only, with a self-signed certificate. Forwards PHP requests to WordPress. |
| **wordpress** | WordPress with php-fpm (port 9000). No web server inside. Installed and configured with WP-CLI. |
| **mariadb** | MariaDB database for WordPress (port 3306), reachable only from the Docker network. |

Everything runs inside a virtual machine and is orchestrated with `docker compose`. The containers are built from `debian:bookworm` (the penultimate stable Debian release at the time of writing). No ready-made image (nginx, wordpress, mariadb) is pulled.

### Project layout

```
.
├── Makefile
├── secrets/                  # passwords (ignored by git)
└── srcs/
    ├── .env                  # non-sensitive variables (ignored by git)
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/   (Dockerfile, conf/, tools/)
        ├── nginx/     (Dockerfile, conf/, tools/)
        └── wordpress/ (Dockerfile, conf/, tools/)
```

### Design choices

- **One process per container.** Each daemon runs in the foreground as PID 1 (`exec mariadbd`, `exec php-fpm8.2 -F`, `nginx -g "daemon off;"`). No `tail -f`, `sleep infinity` or infinite loops are used to keep containers alive.
- **Initialization scripts are idempotent.** MariaDB and WordPress are set up only on the first start, so restarting the stack keeps the data.
- **Passwords never appear in Dockerfiles, the compose file or the repository.** They are read from Docker secrets at runtime.
- **Only port 443 is published** on the host.

### Comparisons

**Virtual Machines vs Docker.** A virtual machine emulates full hardware and runs its own kernel and operating system, which makes it heavy but strongly isolated. A Docker container shares the host kernel and only isolates processes, filesystem and network, so it starts in seconds and uses far fewer resources. In this project the VM is the host environment and Docker runs the services inside it.

**Secrets vs Environment Variables.** Environment variables are simple, but they can leak through `docker inspect`, process listings or logs. Docker secrets are mounted as read-only files under `/run/secrets/` and are not exposed in the environment. This project keeps non-sensitive values (domain, database name, user names) in `.env` and passwords in secrets.

**Docker Network vs Host Network.** With a user-defined bridge network, containers get their own isolated network and reach each other by service name (for example `wordpress` connects to `mariadb:3306`). Only the ports explicitly published are reachable from outside. The host network mode removes this isolation and shares the host's network stack, which is why it is forbidden here.

**Docker Volumes vs Bind Mounts.** Named volumes are managed by Docker and are the recommended way to persist data. Bind mounts map an arbitrary host path directly into a container and depend on the host's directory layout. The two persistent volumes here (`mariadb_data`, `wordpress_data`) are named volumes. They use the local driver with options that place their data in `/home/taewonki/data/`, as the subject requires.

## Instructions

Prerequisites: a Debian/Ubuntu virtual machine with Docker and Docker Compose installed, and `make`.

1. Add the domain to `/etc/hosts`:
   ```
   127.0.0.1 taewonki.42.fr
   ```
2. Create the secrets (they are not stored in git). See [DEV_DOC.md](DEV_DOC.md) for the full list of files.
3. Create `srcs/.env` (see [DEV_DOC.md](DEV_DOC.md)).
4. Build and start everything:
   ```
   make
   ```
5. Open `https://taewonki.42.fr` in a browser (accept the self-signed certificate warning).

Useful targets: `make down`, `make stop`, `make start`, `make logs`, `make ps`, `make clean`, `make fclean`, `make re`.

More documentation:
- [USER_DOC.md](USER_DOC.md) for end users and administrators
- [DEV_DOC.md](DEV_DOC.md) for developers

## Resources

- Docker documentation: https://docs.docker.com/
- Docker Compose file reference: https://docs.docker.com/compose/compose-file/
- Dockerfile best practices: https://docs.docker.com/build/building/best-practices/
- NGINX documentation: https://nginx.org/en/docs/
- MariaDB documentation: https://mariadb.com/kb/en/documentation/
- WP-CLI handbook: https://make.wordpress.org/cli/handbook/
- PHP-FPM configuration: https://www.php.net/manual/en/install.fpm.configuration.php

### Use of AI

AI was used as an assistant for the following tasks:
- Researching and summarizing the subject requirements.
- Drafting the first version of the Dockerfiles, configuration files, entrypoint scripts, Makefile and compose file.
- Drafting the documentation files.
- Explaining concepts such as PID 1, Docker secrets and named volumes with driver options.

All generated content was reviewed, tested in the virtual machine and is understood and explained by the author.
