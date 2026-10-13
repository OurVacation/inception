LOGIN    = taewonki
DATA_DIR = /home/$(LOGIN)/data
COMPOSE  = docker compose -f srcs/docker-compose.yml

all: up

up:
	@mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean: down
	docker system prune -af

fclean: down
	$(COMPOSE) down -v --rmi all
	docker system prune -af
	sudo rm -rf $(DATA_DIR)

re: fclean all

.PHONY: all up down stop start logs ps clean fclean re
