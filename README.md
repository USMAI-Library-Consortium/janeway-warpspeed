# Using / Configuring this Docker Image

Welcome to this unofficial Janeway Docker image, developed by Erik Jones at the USMAI Library Consortium's Consortial Digital Initiatives team in communication with the Janeway dev team. This Docker image is designed to make Janeway flexible and scalable by optimizing it for use in containerized settings. Although this image is built for our upcoming Janeway Helm Chart, it can be used elsewhere provided the right environment variables are set.

The main technical goals of this helm chart were to:
1. Create a production-ready image pre-packaged with nginx and gunicorn
2. Automate the Janeway install process
3. Automate the Janeway upgrade process
4. Automate the plugin install process
5. Automate starting nginx and gunicorn
6. Avoid forking or modifying the Janeway repository

Additional changes were made to optimize the Docker image for Kubernetes, such as:
1. Identifying and consolidating dynamic data storage locations so that they can be persisted
2. Logging to Standard Output
3. Pre-package commonly used plugins, installable using environment variables.

All setup and configuration options are set with environment variables. Please note the required environment variables. Also please note that this Docker image is only compatible with Postgres.

## Docker-Compose

The docker-compose I've provided is **NOT PRODUCTION READY** - it's intended to test the image is working properly. Feel free to base your own docker-compose off of this one - and I'm sure the community would love if you put in a pull request for whatever improvements you make!

## Environment Variables

There are many environment variables needed to make this application run properly. They're divided into five categories:
1. Environment variables always required
2. Environment variables only required when installing Janeway for the first time
3. Optional environment variables
4. Conditionally required environment variables

### Required environment variables:
1. DB_HOST: Hostname of your Postgres DB
2. DB_PORT: Postgres DB Port
3. DB_NAME: Name of your db within postgres
4. DB_USER: Name of the postgres user
5. DB_PASSWORD: Password to connect to the postgres DB
6. JANEWAY_PRESS_DOMAIN: Specifies the Press Domain to use when installing Janeway AND for nginx routing. MUST be the same as the domain name that you give Janeway on your Kubernetes cluster
7. JANEWAY_PRESS_DOMAIN_SCHEME: The scheme for the Janeway domain, e.g. https://, used for CSRF protection

### Environment variables required ONLY when installing Janeway
1. JANEWAY_PRESS_NAME: Specifies the Press Name to use when installing Janeway
2. JANEWAY_PRESS_CONTACT: Specifies the Press Contact email address to use when installing Janeway
3. JANEWAY_JOURNAL_CODE: Specifies the Journal Code to use when installing Janeway
4. JANEWAY_JOURNAL_NAME: Specifies the Journal Name to use when installing Janeway 
5. DJANGO_SUPERUSER_USERNAME
6. DJANGO_SUPERUSER_EMAIL
7. DJANGO_SUPERUSER_PASSWORD

### Optional environment variables
1. JANEWAY_JOURNAL_DESCRIPTION: Only used during Janeway install.
2. JANEWAY_JOURNAL_DOMAIN: Used only during install, this command will specify the domain for the default journal.
3. INSTALL_TYPESETTING_PLUGIN: Install the typesetting plugin - TRUE or FALSE, FALSE if not set
4. INSTALL_PANDOC_PLUGIN: Install the pandoc plugin - TRUE or FALSE, FALSE if not set
5. INSTALL_CUSTOMSTYLING_PLUGIN: Install the custom styling plugin - TRUE or FALSE, FALSE if not set
6. INSTALL_PORTICO_PLUGIN: Install the portico plugin - TRUE or FALSE, FALSE if not set
7. INSTALL_IMPORTS_PLUGIN: Install the imports plugin - TRUE or FALSE, FALSE if not set
8. INSTALL_DOAJ_TRANSPORTER_PLUGIN: Install the doaj_transporter plugin - TRUE or FALSE, FALSE if not set
9. INSTALL_BACK_CONTENT_PLUGIN: Install the back_content plugin - TRUE or FALSE, FALSE if not set
10. INSTALL_REPORTING_PLUGIN: Install the reporting plugin - TRUE or FALSE, FALSE if not set
11. INSTALL_DATACITE_PLUGIN: Install the DataCite plugin - TRUE or FALSE, FALSE if not set
12. DJANGO_DEBUG: Whether to run Django in debug mode.
13. PYTHON_ENABLE_GUNICORN_MULTIWORKERS: Enable Gunicorn multi worker multi thread config. 'true' or 'false', default true.
14. PYTHON_GUNICORN_CUSTOM_WORKER_NUM: Set the number of Gunicorn workers. Only works when PYTHON_ENABLE_GUNICORN_MULTIWORKERS set to 'true'. Default (2 * CPU Core number) + 1
15. PYTHON_GUNICORN_CUSTOM_THREAD_NUM: Set the number of Gunicorn worker threads. Only works when PYTHON_ENABLE_GUNICORN_MULTIWORKERS set to 'true'. Default 1.

### Conditionally required environment variables
1. JANEWAY_JOURNAL_DOMAINS: If Janeway has domains for journals, this is required. Comma separated array (no spaces after commas)
2. JANEWAY_JOURNAL_DOMAIN_SCHEMES: If Janeway has domains for journals, this is required. Schemes are, for example, https://. Comma separated array (no spaces after commas). Each scheme must match a domain in JANEWAY_JOURNAL_DOMAINS by index.