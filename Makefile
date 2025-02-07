# Exposed ports
JANEWAY_PORT ?= 8000
PGADMIN_PORT ?= 8001

# Other required settings
JANEWAY_ENABLE_ORCID=False

unexport NO_DEPS
DB_NAME ?= janeway
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
export JANEWAY_PRESS_NAME=TestPress
export JANEWAY_PRESS_DOMAIN=testpress.com
export JANEWAY_PRESS_CONTACT=ejones99@umd.edu
export JANEWAY_JOURNAL_CODE=test_press
export JANEWAY_JOURNAL_NAME="New Test Journal"

# Variables for Janeway state (controls auto-install and auto-update)
export JANEWAY_VERSION=1.7.3
export DEPLOYMENT_VERSION=0.1.0

export JANEWAY_SUPERUSER_USERNAME=ejones99
export DJANGO_SUPERUSER_PASSWORD=SuperSecureJaneway1234

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
	docker-compose run --rm start_dependencies
	docker-compose $(_VERBOSE) run $(NO_DEPS) --rm --service-ports janeway-web $(entrypoint)
command:	## Run Janeway in a container and pass through a django command passed as the CMD environment variable (e.g make command CMD="migrate -v core 0024")
	docker-compose run $(NO_DEPS) --rm janeway-web $(CMD)
shell:		## Runs the janeway-web service and starts an interactive bash process instead of the webserver
	docker-compose run --service-ports --entrypoint=/bin/bash --rm janeway-web
attach:		## Runs an interactive shell within the currently running janeway-web container.
	docker exec -ti `docker ps -q --filter 'name=janeway-web'` /bin/bash
db-client:	## runs the database CLI client interactively within the database container as per the value of DB_VENDOR
	docker exec -ti `docker ps -q --filter 'name=janeway-postgresql'` $(CLI_COMMAND)
db-save-backup: # Archives the current db as a tarball. Returns the output file name
	@sudo tar -zcf postgres-$(DATE)-$(SUFFIX).tar.gz $(DB_VOLUME)
	@echo "postgres-$(DATE)-$(SUFFIX).tar.gz"
	@sudo chown -R `id -un`:`id -gn` $(DB_VENDOR)-$(DATE)-$(SUFFIX).tar.gz
db-load-backup: #Loads a previosuly captured backup in the db directory (e.g.: make db-load_backup DB=postgres-21-02-03-3948681d1b6dc2.tar.gz)
	@BACKUP=$(BACKUP);echo "Loading $${BACKUP:?Please set to the name of the backup file}"
	@tar -zxf $(BACKUP) -C /tmp/
	@docker kill `docker ps -q --filter 'name=janeway-*'` 2>&1 | true
	@sudo rm -rf $(DB_VOLUME)
	@sudo mv /tmp/$(DB_VOLUME) db/
uninstall:	## Removes all janeway related docker containers, docker images and database volumes
	@bash -c "rm -rf janeway/db/*"
	@bash -c "rm -rf janeway/src/collected-static"
	@bash -c "docker rm -f `docker ps --filter 'name=janeway*' -aq` >/dev/null 2>&1 | true"
	@echo " Janeway has been uninstalled"
check:		## Runs janeway's test suit
	bash -c "DB_VENDOR=sqlite make command CMD=test"
basebuild:		## Builds the base docker image
	bash -c "docker build --no-cache -t janeway:`git rev-parse --abbrev-ref HEAD` ."