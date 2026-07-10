# Using / Configuring this Docker Image

Welcome to this unofficial Janeway Docker image, developed by Erik Jones at the
USMAI Library Consortium's Consortial Digital Initiatives team in communication
with the Janeway dev team. This Docker image is designed to make Janeway
flexible and scalable by optimizing it for use in containerized settings.
Although this image is built for our Janeway Helm Chart, it can be used
elsewhere provided the right environment variables are set.

The main technical goals of this helm chart were to:

1. Create a production-ready image
2. Automate the Janeway install process
3. Automate the Janeway upgrade process
4. Automate the plugin install process
5. Avoid forking or modifying the Janeway repository

Additional changes were made to optimize the Docker image for Kubernetes, such as:

1. Identifying and consolidating dynamic data storage locations so that they can
   be persisted
2. Logging to Standard Output
3. Allow for dynamically installing plugins based on environment variables

All setup and configuration options are set with environment variables. Please
note the required environment variables. Also please note that this Docker
image is only compatible with Postgres (which is a change that Janeway)
will be undergoing anyways.

## Customizing your Janeway

(yes, customize with a 'z'. Hello from across the pond!)

### Using Different Janeway Tags / Forks

While the base Janeway version will be fine for many, others may want to customize
Janeway's code or to use a different version than this repository specifies
by default. Not to worry! While this repository should continue to have a
reasonably-up-to-date Janeway version, you can swap the Janeway version when
building your image with these 3 variables:

`CLONE_REPOSITORY_URL`: The git repository containing your version of Janeway
`CLONE_TAG_VERSION`: The tag of Janeway that you wish to use. This can also
  be a specific commit.
`JANEWAY_VERSION`: Ideally, a version representing an official Janeway release.
If you have your own Janeway source code, you can still use the offical Janeway
release but suffix it with an incrementing number (i.e. v1.8.0-2, v1.8.0-3).
**used only to determine when to update Janeway, so it should represent when
the source code is updated.**

> [!WARNING]
> The JANEWAY_VERSION must always be incrementing, even if you switch source
> code repos. Say you're on Janeway 1.8.0 and decide you need to start maintaning
> your own version. You can have your own version and still keep it incrementing
> with 1.8.0-1, 1.8.0-2, etc. This is a good practice as well as it parallels
> the Janeway versions. If you use a LOWER version the application will refuse to
> launch.

### Installing Plugins

This image has an automated plugin installer, which works by looking in the
`/vol/janeway/src/available-plugins` folder, comparing commit history, and then
copying/installing any new or updated plugins. **This is all done when the
docker image is started, NOT during dockerfile creation.**

In order to install the plugins, you need to extend this dockerfile and
clone the plugins you want into `/vol/janeway/src/available-plugins`. In
your production environment, you must ensure that `/vol/janeway/src/plugins`
is persisted. After this, specify in your production environment which
plugins you want to install using environment variables.

The environment variables should be in the format `INSTALL_<PLUGIN_NAME>_PLUGIN=TRUE`.
Plugin names should be the same as the folder the plugin is cloned into, case
insensitive. If the folder already has a `_plugin` suffix, don't include
`_PLUGIN` twice in the environment variable name.

### Custom Themes

In the event that your insitution wants to use a custom theme, you can
extend this dockerimage and copy your theme into `/vol/janeway/src/themes/`.

## Docker-Compose

The docker-compose I've provided is **NOT PRODUCTION READY** - it's intended to
test the image is working properly. Feel free to base your own docker-compose
off of this one - and I'm sure the community would love if you put in a pull
request for whatever improvements you make!

The docker-compose is supposed to be run through Make. You can run the
application by typing 'make janeway'. You can uninstall the application by
typing 'make uninstall'.

Don't modify the Makefile or docker-compose if you just want to change Janeway
settings. Instead, create a file called 'Makefile.local' in the root of this
repository. There, you can override or set any environment variables used to
configure Janeway. This will not interfere with Git, as I've set Git to ignore
that file.

## Environment Variables

There are many environment variables needed to make this application run
properly. In Docker-Compose, all required ones have been set some testing default.

This does not include the environment variables mentioned in the "Using
Different Janeway Tags / Forks" section above. These must be included but
have defaults set.

If you want to create your own deployment, or change settings, the environment
variables are divided into four categories:

1. Environment variables always required
2. Environment variables only required when installing Janeway for the first time
3. Optional environment variables
4. Conditionally required environment variables

### Required Environment Variables

1. DB_HOST: Hostname of your Postgres DB
2. DB_PORT: Postgres DB Port
3. DB_NAME: Name of the Postgres DB
4. DB_USER: Name of the postgres user
5. DB_PASSWORD: Password to connect to the postgres DB
6. JANEWAY_PRESS_DOMAIN: Specifies the Press Domain to use when installing
   Janeway AND for nginx routing. MUST be the same as the domain name that you
   give Janeway on your Kubernetes cluster
7. JANEWAY_PRESS_DOMAIN_SCHEME: The scheme for the Janeway domain, e.g.
   https://, used for CSRF protection

### Environment Variables Required ONLY when Installing Janeway

1. JANEWAY_PRESS_NAME: Specifies the Press Name to use when installing Janeway
2. JANEWAY_PRESS_CONTACT: Specifies the Press Contact email address to use when
   installing Janeway
3. JANEWAY_JOURNAL_CODE: Specifies the Journal Code to use when installing Janeway
4. JANEWAY_JOURNAL_NAME: Specifies the Journal Name to use when installing Janeway
5. DJANGO_SUPERUSER_USERNAME
6. DJANGO_SUPERUSER_EMAIL
7. DJANGO_SUPERUSER_PASSWORD

### Optional environment variables

1. JANEWAY_JOURNAL_DESCRIPTION: Only used during Janeway install. Specifies the
   description of the auto-created journal.
2. JANEWAY_JOURNAL_DOMAIN: Used only during install, this command will specify
   the domain for the auto-created journal. If no domain is specified, the
   journal will be accessible only as a subpath on the Press site (which should
   be fine in many cases)
3. DJANGO_DEBUG: Whether to run Django in debug mode. Should always be 'off' in
   production.
4. PYTHON_ENABLE_GUNICORN_MULTIWORKERS: Enable Gunicorn multi worker multi
   thread config. 'true' or 'false', default true.
5. PYTHON_GUNICORN_CUSTOM_WORKER_NUM: Set the number of Gunicorn workers. Only
   works when PYTHON_ENABLE_GUNICORN_MULTIWORKERS set to 'true'. Default
   (2 * CPU Core number) + 1
6. PYTHON_GUNICORN_CUSTOM_THREAD_NUM: Set the number of Gunicorn worker
   threads. Only works when PYTHON_ENABLE_GUNICORN_MULTIWORKERS set to 'true'.
   Default 1.

### Conditionally required environment variables

1. JANEWAY_JOURNAL_DOMAINS: If Janeway uses seperate domains for journals, you
have to to configure internal networking. Comma separated list (no spaces after
commas). Domain only, no schemes (e.g., https://)
2. JANEWAY_JOURNAL_DOMAIN_SCHEMES: If Janeway uses seperate domains for
journals, this is required to configure internal networking. Schemes are, for
example, https://. Comma separated list (no spaces after commas). Each scheme
must match a domain in JANEWAY_JOURNAL_DOMAINS by index.
