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
    for var in JANEWAY_PRESS_NAME JANEWAY_PRESS_DOMAIN JANEWAY_PRESS_CONTACT JANEWAY_JOURNAL_CODE JANEWAY_JOURNAL_NAME; do
        if [[ -z "${!var}" ]]; then
            echo "Missing required environment variable: $var"
            exit 1
        fi
    done
    
    python3 src/manage.py install_janeway_k8s 2>&1
    STATUS=$?

    if [[ $STATUS == "0" ]]; then
        echo "Install successful."
        echo $JANEWAY_VERSION > /var/www/janeway/state-data/INSTALLED_APPLICATION_VERSION
    else
        echo "Install Failed"
        exit 1
    fi
else
    INSTALLED_APPLICATION_VERSION=$(cat /var/www/janeway/state-data/INSTALLED_APPLICATION_VERSION)
    INCOMING_APPLICATION_VERSION=$JANEWAY_VERSION

    # Application version check
    # Throws an error if the incoming version is less than the installed version.
    if [[ "$(printf '%s\n' "$INSTALLED_APPLICATION_VERSION" "$INCOMING_APPLICATION_VERSION" | sort --version-sort | tail --lines 1)" != "$INCOMING_APPLICATION_VERSION" ]]; then
        echo "FATAL ERROR: Incoming Janeway version $INCOMING_APPLICATION_VERSION is less than installed version $INSTALLED_APPLICATION_VERSION"
        exit 1
    fi

    if [[ "$INSTALLED_APPLICATION_VERSION" != "$INCOMING_APPLICATION_VERSION" ]]; then
        # Upgrade Janeway & plugins
        echo "Upgrading Janeway from $INSTALLED_APPLICATION_VERSION to $INCOMING_APPLICATION_VERSION..."
        python3 src/manage.py upgrade_janeway_k8s 2>&1
        STATUS=$?
        if [[ $STATUS == "0" ]]; then
            echo "Upgrade successful!"
            echo $INCOMING_APPLICATION_VERSION > /var/www/janeway/state-data/INSTALLED_APPLICATION_VERSION
        else
            echo "FATAL ERROR: Upgrade Failed!"
            exit 1
        fi
    else
        echo "Janeway is up-to-date ($INSTALLED_APPLICATION_VERSION)."

        # Upgrade plugins
        echo "Running plugin update/install process..."
        python3 src/manage.py manage_plugins_k8s 2>&1
        python3 src/manage.py clear_cache 2>&1
        python3 src/manage.py install_cron 2>&1
    fi
fi

cd /vol/janeway/src
mkdir -p /var/www/janeway/logs
/opt/venv/bin/gunicorn --access-logfile - --error-logfile - --threads 1 --workers 2 --bind unix:/tmp/gunicorn.sock core.wsgi:application & nginx -g 'daemon off;'
