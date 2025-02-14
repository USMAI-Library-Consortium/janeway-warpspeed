#!/bin/bash
set -e

# Ensure required environment variables are set
if [[ -z "$DB_HOST" || -z "$DB_PORT" || -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASSWORD" ]]; then
    echo "Missing required environment variables for DB connection."
    exit 1
fi

# Check if the database exists
export PGPASSWORD=$DB_PASSWORD
JANEWAY_DATABASE=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT * FROM pg_database WHERE datname='$DB_NAME';")
# Get the database name - Will be the first field in fields seperated by '|'
JANEWAY_DATABASE_EXISTS=$(cut -d "|" -f 1 <<< $JANEWAY_DATABASE)

echo $JANEWAY_DATABASE_EXISTS

if [[ "$JANEWAY_DATABASE_EXISTS" == $DB_NAME ]]; then
    DATABASE_EXISTS=0
else
    DATABASE_EXISTS=1
fi

if [[ $DB_EXISTS==0 ]]; then
    echo "Database '$DB_NAME' exists."
else
    echo "Database '$DB_NAME' does not exist or connection failed."
    exit 1
fi

cd /vol/janeway
source "$VENV_PATH/bin/activate"

if [[ $(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT * FROM information_schema.tables WHERE table_schema='public';") ]]; then
    JANEWAY_INSTALLED=0
    echo "Janeway application is installed."
else
    JANEWAY_INSTALLED=1
    echo "Janeway application is not installed."
fi

if [[ "$JANEWAY_INSTALLED" == "1" ]]; then
    # Ensure required environment variables are set
    if [[ -z "$JANEWAY_PRESS_NAME" ]]; then
        echo "Missing required Janeway Press Name environment variable."
        exit 1
    elif [[ -z "$JANEWAY_PRESS_DOMAIN" ]]; then
        echo "Missing required Janeway Press Domain environment variable."
        exit 1
    elif [[ -z "$JANEWAY_PRESS_CONTACT" ]]; then
        echo "Missing required Janeway Press Contact environment variable."
        exit 1
    elif [[ -z "$JANEWAY_JOURNAL_CODE" ]]; then
        echo "Missing required Janeway Journal Code environment variable."
        exit 1
    elif [[ -z "$JANEWAY_JOURNAL_NAME" ]]; then
        echo "Missing required Janeway Journal Name environment variable."
        exit 1
    fi
    
    python3 src/manage.py install_janeway_k8s 2>&1
    STATUS=$?

    if [[ $STATUS == "0" ]]; then
        echo "Install successful."
        mkdir -p /var/www/janeway/state-data/
        echo $DEPLOYMENT_VERSION > /var/www/janeway/state-data/INSTALLED_DEPLOYMENT_VERSION
        echo $JANEWAY_VERSION > /var/www/janeway/state-data/INSTALLED_APPLICATION_VERSION
    else
        echo "Install Failed"
        exit 1
    fi
else
    echo "Checking if Janeway deployment update is needed..."
    INSTALLED_VERSION=$(cat /var/www/janeway/state-data/INSTALLED_DEPLOYMENT_VERSION)
    INCOMING_VERSION=$DEPLOYMENT_VERSION

    if [[ "$(printf '%s\n' "$INSTALLED_VERSION" "$INCOMING_VERSION" | sort -V | tail -n 1)" == "$INCOMING_VERSION" ]]; then

        if [[ "$INSTALLED_VERSION" != "$INCOMING_VERSION" ]]; then
            echo "Deployment version $INSTALLED_VERSION is out of date; installing version $INCOMING_VERSION..."

            python3 src/manage.py build_assets
            python3 src/manage.py collectstatic --no-input
            DJANGO_SETTINGS_MODULE=1 python3 src/manage.py compilemessages
            python3 src/manage.py load_default_settings
            python3 src/manage.py update_repository_settings
            python3 src/manage.py collectplugins
            python3 src/manage.py install_plugins
            python3 src/manage.py update_translation_fields
            python3 src/manage.py install_cron
            python3 src/manage.py clear_cache
            echo $DEPLOYMENT_VERSION > /var/www/janeway/state-data/INSTALLED_DEPLOYMENT_VERSION
            echo $JANEWAY_VERSION > /var/www/janeway/state-data/INSTALLED_APPLICATION_VERSION
        else
            echo "Janeway version up-to-date."
        fi
    else
        echo "FATAL ERROR; incoming Deployment version $INCOMING_VERSION is less than installed version $INSTALLED_VERSION"
        exit 1
    fi
fi

cd /vol/janeway/src
mkdir -p /var/www/janeway/logs
/opt/venv/bin/gunicorn --access-logfile - --error-logfile - --threads 1 --workers 2 --bind unix:/tmp/gunicorn.sock core.wsgi:application & nginx -g 'daemon off;'
