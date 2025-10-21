# Using / Configuring this Docker Image

Welcome to this unofficial Janeway Docker image, developed by Erik Jones at the USMAI Library Consortium's Consortial Digital Initiatives team in communication with the Janeway dev team. This Docker image is designed to make Janeway flexible and scalable by optimizing it for use in containerized settings. Although this image is built for our upcoming Janeway Helm Chart, it can be used elsewhere provided the right environment variables are set.

The main technical goals of this helm chart were to:
1. Create a production-ready image
2. Automate the Janeway install process
3. Automate the Janeway upgrade process
4. Automate the plugin install process
5. Avoid forking or modifying the Janeway repository

Additional changes were made to optimize the Docker image for Kubernetes, such as:
1. Identifying and consolidating dynamic data storage locations so that they can be persisted
2. Logging to Standard Output
3. Pre-package commonly used plugins, installable using environment variables.

All setup and configuration options are set with environment variables. Please note the required environment variables. Also please note that this Docker image is only compatible with Postgres.

## Docker-Compose

The docker-compose I've provided is **NOT PRODUCTION READY** - it's intended to test the image is working properly. Feel free to base your own docker-compose off of this one - and I'm sure the community would love if you put in a pull request for whatever improvements you make!

The docker-compose is supposed to be run through Make! You can run the application by typing 'make janeway'. You can uninstall the application by typing 'make uninstall'.

Don't modify the Makefile or docker-compose if you just want to change Janeway settings. Instead, create a file called 'Makefile.local' in the root of this repository. There, you can override or set any environment variables used to configure Janeway. This will not interfere with Git, as I've set Git to ignore that file. 

## Environment Variables

There are many environment variables needed to make this application run properly. In Docker-Compose, all required ones have been set some testing default. 

If you want to create your own deployment, or change settings, the environment variables are divided into four categories:
1. Environment variables always required
2. Environment variables only required when installing Janeway for the first time
3. Optional environment variables
4. Conditionally required environment variables

### Required Environment Variables:
1. DB_HOST: Hostname of your Postgres DB
2. DB_PORT: Postgres DB Port
3. DB_NAME: Name of the Postgres DB
4. DB_USER: Name of the postgres user
5. DB_PASSWORD: Password to connect to the postgres DB
6. JANEWAY_PRESS_DOMAIN: Specifies the Press Domain to use when installing Janeway AND for nginx routing. MUST be the same as the domain name that you give Janeway on your Kubernetes cluster
7. JANEWAY_PRESS_DOMAIN_SCHEME: The scheme for the Janeway domain, e.g. https://, used for CSRF protection

### Environment Variables Required ONLY when Installing Janeway
1. JANEWAY_PRESS_NAME: Specifies the Press Name to use when installing Janeway
2. JANEWAY_PRESS_CONTACT: Specifies the Press Contact email address to use when installing Janeway
3. JANEWAY_JOURNAL_CODE: Specifies the Journal Code to use when installing Janeway
4. JANEWAY_JOURNAL_NAME: Specifies the Journal Name to use when installing Janeway 
5. DJANGO_SUPERUSER_USERNAME
6. DJANGO_SUPERUSER_EMAIL
7. DJANGO_SUPERUSER_PASSWORD

### Optional environment variables
1. JANEWAY_JOURNAL_DESCRIPTION: Only used during Janeway install. Specifies the description of the auto-created journal.
2. JANEWAY_JOURNAL_DOMAIN: Used only during install, this command will specify the domain for the auto-created journal. If no domain is specified, the journal will be accessible only as a subpath on the Press site (which should be fine in many cases)
3. INSTALL_PANDOC_PLUGIN: Install the pandoc plugin - TRUE or FALSE, FALSE if not set
4. INSTALL_CUSTOMSTYLING_PLUGIN: Install the custom styling plugin - TRUE or FALSE, FALSE if not set
5. INSTALL_PORTICO_PLUGIN: Install the portico plugin - TRUE or FALSE, FALSE if not set
6. INSTALL_IMPORTS_PLUGIN: Install the imports plugin - TRUE or FALSE, FALSE if not set
7. INSTALL_DOAJ_TRANSPORTER_PLUGIN: Install the doaj_transporter plugin - TRUE or FALSE, FALSE if not set
8. INSTALL_BACK_CONTENT_PLUGIN: Install the back_content plugin - TRUE or FALSE, FALSE if not set
9. INSTALL_REPORTING_PLUGIN: Install the reporting plugin - TRUE or FALSE, FALSE if not set
10. INSTALL_DATACITE_PLUGIN: Install the DataCite plugin - TRUE or FALSE, FALSE if not set
11. DJANGO_DEBUG: Whether to run Django in debug mode. Should always be 'off' in production.
12. PYTHON_ENABLE_GUNICORN_MULTIWORKERS: Enable Gunicorn multi worker multi thread config. 'true' or 'false', default true.
13. PYTHON_GUNICORN_CUSTOM_WORKER_NUM: Set the number of Gunicorn workers. Only works when PYTHON_ENABLE_GUNICORN_MULTIWORKERS set to 'true'. Default (2 * CPU Core number) + 1
14. PYTHON_GUNICORN_CUSTOM_THREAD_NUM: Set the number of Gunicorn worker threads. Only works when PYTHON_ENABLE_GUNICORN_MULTIWORKERS set to 'true'. Default 1.

### Conditionally required environment variables
1. JANEWAY_JOURNAL_DOMAINS: If Janeway uses seperate domains for journals, this is required to configure internal networking. Comma separated list (no spaces after commas). Domain only, no schemes (e.g., https://)
2. JANEWAY_JOURNAL_DOMAIN_SCHEMES: If Janeway uses seperate domains for journals, this is required to configure internal networking. Schemes are, for example, https://. Comma separated list (no spaces after commas). Each scheme must match a domain in JANEWAY_JOURNAL_DOMAINS by index.