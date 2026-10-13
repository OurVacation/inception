# Developer Documentation

## Set up the environment from scratch

### Prerequisites

- A virtual machine running Debian or Ubuntu
- `git`, `make`, `openssl`
- Docker Engine and the Docker Compose plugin (`docker compose`)
- Your user in the `docker` group (log out and back in after `usermod -aG docker <user>`)

### Domain name

Point the domain to the local machine:

```
echo "127.0.0.1 taewonki.42.fr" | sudo tee -a /etc/hosts
```

### Configuration files

Clone the repository, then create the two things that are not in git.

**1. `srcs/.env`** (non-sensitive values only):

```
DOMAIN_NAME=taewonki.42.fr

# MYSQL SETUP
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

# WORDPRESS SETUP
WP_TITLE=Inception
WP_ADMIN_USER=<administrator name, must not contain "admin" or "administrator">
WP_ADMIN_EMAIL=<e-mail>
WP_USER=<second user name>
WP_USER_EMAIL=<e-mail>
```

**2. `secrets/`** (one file per password, each containing only the password):

```
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

Both `secrets/` and `srcs/.env` are listed in `.gitignore`. Never commit them.

Avoid single quotes and backticks in passwords because they are inserted into an SQL statement by `mariadb/tools/init.sh`.

## Build and launch the project

The Makefile wraps `docker compose -f srcs/docker-compose.yml`:

| Command | What it does |
|---|---|
| `make` | Creates `/home/taewonki/data/{mariadb,wordpress}`, builds the images and starts the stack in the background |
| `make down` | Stops and removes the containers and the network (volumes and data are kept) |
| `make stop` / `make start` | Stops / starts the existing containers |
| `make logs` | Follows the logs of all services |
| `make ps` | Shows the container status |
| `make clean` | `make down` and prunes unused Docker objects |
| `make fclean` | Removes containers, images, volumes and `/home/taewonki/data` |
| `make re` | `make fclean` and then `make` |

## Manage the containers and volumes

```
docker compose -f srcs/docker-compose.yml ps
docker exec -it wordpress sh          # shell in a container
docker logs <container>               # logs of one container
docker volume ls                      # list volumes
docker volume inspect mariadb_data wordpress_data
docker network ls                     # the "inception" network
docker top <container>                # processes (PID 1 is the daemon)
```

Check the WordPress users:

```
docker exec wordpress wp user list --allow-root --path=/var/www/html
```

## Where the data is stored and how it persists

The two named volumes are declared in `srcs/docker-compose.yml` with the `local` driver and options that place their data on the host:

| Volume | Container path | Host path |
|---|---|---|
| `mariadb_data` | `/var/lib/mysql` | `/home/taewonki/data/mariadb` |
| `wordpress_data` | `/var/www/html` | `/home/taewonki/data/wordpress` |

Because the data lives on the host, it survives `make down`, container restarts and rebuilds. It is only deleted by `make fclean`.

The entrypoint scripts check the volume content on every start:
- `mariadb/tools/init.sh` initializes the system tables and creates the database and users only if they do not exist yet, then runs `mariadbd` as PID 1.
- `wordpress/tools/setup.sh` waits for MariaDB, downloads and installs WordPress with WP-CLI only if `wp-config.php` is missing, then runs `php-fpm8.2 -F` as PID 1.

### How secrets are passed

`docker-compose.yml` declares the files in `secrets/` under the `secrets:` key, and each service lists only the secrets it needs. They appear inside the container as files in `/run/secrets/<name>`, which the scripts read at runtime.

| Secret | mariadb | wordpress |
|---|---|---|
| `db_password` | yes | yes |
| `db_root_password` | yes | no |
| `wp_admin_password` | no | yes |
| `wp_user_password` | no | yes |

### Services

| Service | Image | Notes |
|---|---|---|
| `nginx` | built from `debian:bookworm` | Self-signed certificate generated at build time, TLSv1.2/1.3, port 443 published |
| `wordpress` | built from `debian:bookworm` | php-fpm on port 9000, WP-CLI |
| `mariadb` | built from `debian:bookworm` | Port 3306 on the internal network only |

All containers use `restart: always` and are connected to the `inception` bridge network.
