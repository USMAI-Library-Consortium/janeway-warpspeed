# Exposed ports
JANEWAY_PORT=8000
PGADMIN_PORT=8001

# Other required settings
JANEWAY_ENABLE_ORCID=False

unexport NO_DEPS
DB_NAME ?= janeway
DB_HOST=janeway-postgres
DB_PORT=5432
DB_USER=janeway-web
DB_PASSWORD=janeway-web
DB_VOLUME=janeway/db/postgres-data
CLI_COMMAND=psql --username=$(DB_USER) $(DB_NAME)

ifdef VERBOSE
	_VERBOSE=--verbose
endif

# Email
JANEWAY_EMAIL_BACKEND=''
JANEWAY_EMAIL_HOST=''
JANEWAY_EMAIL_PORT=''
JANEWAY_EMAIL_USE_TLS=0

ifdef DEBUG_SMTP
	JANEWAY_EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
	JANEWAY_EMAIL_HOST=janeway-debug-smtp
	JANEWAY_EMAIL_PORT=1025
	JANEWAY_EMAIL_USE_TLS=
endif

export DB_VENDOR=postgres
export DB_HOST
export DB_PORT
export DB_NAME
export DB_USER
export DB_PASSWORD
export JANEWAY_PORT
export PGADMIN_PORT

export JANEWAY_EMAIL_BACKEND
export JANEWAY_EMAIL_HOST
export JANEWAY_EMAIL_PORT
export JANEWAY_EMAIL_USE_TLS

export JANEWAY_ENABLE_ORCID

# Install variables
export JANEWAY_PRESS_NAME=Test Press
export JANEWAY_PRESS_DOMAIN=localhost:${JANEWAY_PORT}
export JANEWAY_PRESS_DOMAIN_SCHEME=http://
export JANEWAY_PRESS_CONTACT=test@example.com
export JANEWAY_JOURNAL_CODE=test_journal
export JANEWAY_JOURNAL_NAME=New Test Journal

# Variables for Janeway state (controls auto-install and auto-update)
export JANEWAY_VERSION=1.7.5

export DJANGO_SUPERUSER_EMAIL=test@example.com
export DJANGO_SUPERUSER_USERNAME=johndoe
export DJANGO_SUPERUSER_PASSWORD=SuperSecureJaneway1234

export INSTALL_CRON=TRUE

SUFFIX ?= $(shell date +%s)
SUFFIX := ${SUFFIX}
DATE := `date +"%y-%m-%d"`

.PHONY: janeway
all: help
run: janeway
help:		## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'
janeway:	## Run Janeway web server in attached mode. If NO_DEPS is not set, runs all dependant services detached.
	docker-compose build
	-docker-compose run --rm start_janeway_dependencies || true
	-docker-compose run --rm start_nginx_dependencies || true
	-docker-compose up || true
	make down
uninstall:	## Removes all janeway related docker containers, docker images and database volumes
	@bash -c "rm -rf ./dockervols/*"
	@bash -c "docker ps --filter 'name=janeway*' -aq | xargs -r docker rm -f >/dev/null 2>&1 || true"
	@echo " Janeway has been uninstalled"
down:
	docker-compose down
shell:		## Runs the janeway-web service and web server, then shell in
	docker-compose run --rm start_janeway_dependencies
	docker-compose up -d janeway-web
	-docker-compose exec janeway-web /bin/bash || true
	make down