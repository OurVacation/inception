# User Documentation

## Services provided

| Service | Purpose | Access |
|---|---|---|
| **nginx** | HTTPS entrypoint of the stack | `https://taewonki.42.fr` (port 443) |
| **wordpress** | The WordPress website (php-fpm) | Through nginx |
| **mariadb** | Database used by WordPress | Internal only, not reachable from outside |

## Start and stop the project

Run these commands from the root of the repository:

| Action | Command |
|---|---|
| Build and start | `make` |
| Stop (keep containers) | `make stop` |
| Start again | `make start` |
| Stop and remove containers | `make down` |
| Full cleanup (containers, images, volumes, data) | `make fclean` |

> `make fclean` deletes all website and database data in `/home/taewonki/data`.

## Access the website and the administration panel

1. Make sure `/etc/hosts` contains `127.0.0.1 taewonki.42.fr`.
2. Website: open `https://taewonki.42.fr`.
3. Administration panel: open `https://taewonki.42.fr/wp-admin`.

The browser shows a security warning because the TLS certificate is self-signed. Choose to continue anyway.

Plain HTTP on port 80 is not available.

## Locate and manage credentials

Passwords are stored as files in the `secrets/` folder at the root of the repository. They are not stored in git.

| File | Used for |
|---|---|
| `secrets/db_password.txt` | Password of the WordPress database user |
| `secrets/db_root_password.txt` | Password of the MariaDB root user |
| `secrets/wp_admin_password.txt` | Password of the WordPress administrator |
| `secrets/wp_user_password.txt` | Password of the second WordPress user |

Non-sensitive values (domain name, database name, user names, e-mails) are in `srcs/.env`.

To read a password: `cat secrets/wp_admin_password.txt`.

> The database and WordPress accounts are created on the first start only. If you change a password file afterwards, run `make fclean` and then `make` so the accounts are created again with the new values.

## Check that the services are running correctly

1. List the containers. `mariadb`, `wordpress` and `nginx` must all be `Up`:
   ```
   make ps
   ```
2. Check that the website answers over HTTPS:
   ```
   curl -k -I https://taewonki.42.fr
   ```
3. Check the logs if something is wrong:
   ```
   docker logs mariadb
   docker logs wordpress
   docker logs nginx
   ```
4. Log in to `https://taewonki.42.fr/wp-admin` with the administrator account defined in `srcs/.env` (`WP_ADMIN_USER`).
