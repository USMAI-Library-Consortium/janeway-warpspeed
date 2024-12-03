#!/bin/bash

set -e

# Ensure required environment variables are set
if [[ -z "$DB_HOST" || -z "$DB_PORT" || -z "$DB_NAME" || -z "$POSTGRES_USER" || -z "$POSTGRES_PASSWORD" ]]; then
    echo "Missing required environment variables for DB connection."
    exit 1
fi

# Check if the database exists
export PGPASSWORD=$POSTGRES_PASSWORD

DB_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';")

if [[ "$DB_EXISTS" == "1" ]]; then
    echo "Database $DB_NAME exists."
    JANEWAY_INSTALLED=TRUE
else
    echo "Database $DB_NAME does not exist."
    JANEWAY_INSTALLED=FALSE
fi

cd /vol/janeway
source "$VENV_PATH/bin/activate"

if [[ "$JANEWAY_INSTALLED" == FALSE ]]; then
    # Ensure required environment variables are set
    if [[ -z "$JANEWAY_PRESS_NAME" || -z "$JANEWAY_PRESS_DOMAIN" || -z "$JANEWAY_PRESS_CONTACT" || -z "$JANEWAY_JOURNAL_CODE" || -z "$JANEWAY_JOURNAL_NAME" ]]; then
        echo "Missing required environment variables for janeway install."
        exit 1
    fi

    if [[ $USE_TYPESETTING_PLUGIN == TRUE ]]; then
        rm -rf /vol/janeway/src/plugins/typesetting
        cp -r /tmp/plugins/typesetting /vol/janeway/src/plugins
    fi
    if [[ $USE_PANDOC_PLUGIN == TRUE ]]; then
        rm -rf /vol/janeway/src/plugins/pandoc_plugin
        cp -r /tmp/plugins/pandoc_plugin /vol/janeway/src/plugins
    fi

    python3 src/manage.py install_janeway --use-defaults
else
    INSTALLED_VERSION=INSTALLED_VERSION=$(psql -U admin -d "postgres-janeway" -tc "SELECT MAX(number) FROM utils_version" | xargs)
    python3 src/manage.py migrate
    INCOMING_VERSION=INSTALLED_VERSION=$(psql -U admin -d "postgres-janeway" -tc "SELECT MAX(number) FROM utils_version" | xargs)

    if [[ "$(printf '%s\n' "$INSTALLED_VERSION" "$INCOMING_VERSION" | sort -V | tail -n 1)" == "$INCOMING_VERSION" ]]; then

        if [[ "$INSTALLED_VERSION" != "$INCOMING_VERSION" ]]; then
            echo "Installed version $INSTALLED_VERSION is out of date; installing version $INCOMING_VERSION..."

            if [[ $USE_TYPESETTING_PLUGIN == TRUE ]]; then
                rm -rf /vol/janeway/src/plugins/typesetting
                cp -r /tmp/plugins/typesetting /vol/janeway/src/plugins
            fi
            if [[ $USE_PANDOC_PLUGIN == TRUE ]]; then
                rm -rf /vol/janeway/src/plugins/pandoc_plugin
                cp -r /tmp/plugins/pandoc_plugin /vol/janeway/src/plugins
            fi
            
            python3 src/manage.py load_default_settings
            python3 src/manage.py update_repository_settings
            python3 src/manage.py install_plugins
            python3 src/manage.py install_cron
            python3 src/manage.py populate_history cms.Page comms.NewsItem repository.Repository
            python3 src/manage.py clear_cache
        else
            echo "Janeway version up-to-date."
        fi
    else
        echo "FATAL ERROR; incoming Janeway version $INCOMING_VERSION is less than installed version $INSTALLED_VERSION"
        exit 1
    fi
fi

cd /vol/janeway/src
gunicorn core.wsgi:application