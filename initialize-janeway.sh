#!/bin/bash
set -e

# Ensure required environment variables are set
for var in DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD JANEWAY_VERSION JANEWAY_PORT; do
    if [[ -z "${!var}" ]]; then
        echo "Missing required environment variable: $var"
        exit 1
    fi
done

# Check if the database exists
export PGPASSWORD=$DB_PASSWORD
JANEWAY_DATABASE=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT * FROM pg_database WHERE datname='$DB_NAME';")
# Get the database name - Will be the first field in fields seperated by '|'
JANEWAY_DATABASE_EXISTS=$(cut -d "|" -f 2 <<< $JANEWAY_DATABASE)

# If the database does not exist, exit.
if [[ ${JANEWAY_DATABASE_EXISTS,,} == ${DB_NAME,,} ]]; then
    echo "Database '$DB_NAME' exists."
else
    echo "Database '$DB_NAME' does not exist or connection failed."
    exit 1
fi

# Set up persisted folders
for var in state-data logs collected-static media; do
    mkdir -p /var/www/janeway/${var}
done

cd /vol/janeway
source "$VENV_PATH/bin/activate"

if [[ $(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT * FROM information_schema.tables WHERE table_schema='public';") ]]; then
    JANEWAY_INSTALLED=0
    echo "Janeway application is installed."
else
    JANEWAY_INSTALLED=1
    echo "Janeway application is not installed."
fi

# Janeway is NOT installed
if [[ "$JANEWAY_INSTALLED" == "1" ]]; then
    # Ensure required environment variables are set
    for var in JANEWAY_PRESS_NAME JANEWAY_PRESS_DOMAIN JANEWAY_PRESS_CONTACT JANEWAY_JOURNAL_CODE JANEWAY_JOURNAL_NAME; do
        if [[ -z "${!var}" ]]; then
            echo "Missing required environment variable: $var"
            exit 1
        fi
    done

    # Get the domain for the default journal from the list of journal domains.
    # If there are no journal domains or if the DEFAULT_JOURNAL_DOMAIN_INDEX is not set
    # this will be empty
    export JANEWAY_JOURNAL_DOMAIN=$(python3 /usr/local/bin/extract_default_journal_domain.py)

    if [[ -z "$JANEWAY_JOURNAL_DOMAIN" ]]; then
        echo "No Janeway Journal Domain Specified"
    else
        echo "Domain for the Auto-Installed Janeway Journal is $JANEWAY_JOURNAL_DOMAIN"
    fi
    
    python3 src/manage.py install_janeway --use-defaults 2>&1
    python3 src/manage.py createsuperuser --no-input --email="$DJANGO_SUPERUSER_EMAIL" 2>&1
    python3 src/manage.py migrate 2>&1

    echo "Install successful."
    echo $JANEWAY_VERSION > /var/www/janeway/state-data/INSTALLED_APPLICATION_VERSION

# Janeway IS installed
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
        python3 src/manage.py upgrade_janeway 2>&1
        python3 src/manage.py migrate 2>&1
        
        echo "Upgrade successful!"
        echo $INCOMING_APPLICATION_VERSION > /var/www/janeway/state-data/INSTALLED_APPLICATION_VERSION
    else
        echo "Janeway is up-to-date ($INSTALLED_APPLICATION_VERSION)."

        # Upgrade plugins
        echo "Running plugin update/install process..."
        python3 src/manage.py manage_plugins 2>&1
        python3 src/manage.py migrate 2>&1
        # Build assets, in case user has modified themes
        python3 src/manage.py build_assets 2>&1
        python3 src/manage.py clear_cache 2>&1

        if [[ ${INSTALL_CRON,,} == "true" ]]; then
            python3 src/manage.py install_cron 2>&1
        else
            echo "Internal Cron installation disabled."
        fi
    fi
fi
