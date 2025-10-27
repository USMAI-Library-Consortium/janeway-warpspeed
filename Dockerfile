FROM python:3.11
SHELL ["/bin/bash", "-c"]

# ----------------------- DEBIAN DEPENDENCIES -----------------------
RUN apt-get update
RUN apt-get install -y gettext pandoc cron postgresql-client \
    libxml2-dev libxslt1-dev zlib1g-dev libffi-dev \
    libssl-dev libjpeg-dev

# ----------------------- ENVIRONMENT VARIABLES ---------------------
ENV VENV_PATH=/opt/venv
ENV PATH="$VENV_PATH/bin:$PATH"
ENV STATIC_DIR=/var/www/janeway/collected-static
ENV MEDIA_DIR=/var/www/janeway/media
ENV JANEWAY_VERSION="1.8.0-RC-9"
ENV DB_VENDOR="postgres"
ENV PYTHON_ENABLE_GUNICORN_MULTIWORKERS='true'

# Create the virtual environment
RUN python3 -m venv $VENV_PATH

# ------------------------ JANEWAY MAIN PYTHON DEPENDENCIES ----------------------
# Clone Janeway into tmp directory
WORKDIR /tmp
RUN git clone https://github.com/openlibhums/janeway.git
RUN cd janeway && git switch --detach v1.8.0-RC-9

# Install Python required packages
RUN mkdir -p /vol/janeway/
RUN cp ./janeway/requirements.txt /vol/janeway
WORKDIR /vol/janeway
RUN source ${VENV_PATH}/bin/activate && pip3 install -r requirements.txt
RUN source ${VENV_PATH}/bin/activate && pip3 install 'gunicorn>=23.0.0,<24.0.0'


# ----------------------- JANEWAY PLUGINS --------------------------
# Copy all installable plugins into a temp directory, to be collected and installed later
WORKDIR /vol/janeway/src/available-plugins
RUN git clone https://github.com/openlibhums/pandoc_plugin.git --branch v1.0.0-RC-1
RUN git clone https://github.com/openlibhums/back_content.git --branch v1.7.0-RC-1
RUN git clone https://github.com/openlibhums/customstyling.git --branch v1.1.1
RUN git clone https://github.com/openlibhums/doaj_transporter.git --branch master && pip3 install marshmallow
RUN git clone https://github.com/openlibhums/imports.git --branch v1.11
RUN source ${VENV_PATH}/bin/activate && pip3 install -r /vol/janeway/src/available-plugins/imports/requirements.txt
RUN git clone https://github.com/openlibhums/portico.git
RUN source ${VENV_PATH}/bin/activate && pip3 install -r /vol/janeway/src/available-plugins/portico/requirements.txt 
RUN git clone https://github.com/openlibhums/reporting.git --branch v1.3-RC-1
RUN git clone https://github.com/openlibhums/datacite.git --branch v0.5.0

# Don't generate pycache files for Janeway during runtime -
# That's why its not with the other ENV Variables - I'm allowing
# it for the pip3 install but not Janeway
ENV PYTHONDONTWRITEBYTECODE=1

# ----------------------- JANEWAY SOURCE CODE --------------------------
WORKDIR /tmp/janeway
RUN cp -r src /vol/janeway/
# Copy custom settings file into Janeway
COPY prod_settings.py /vol/janeway/src/core/
# Copy kubernetes install and setup script into Janeway
RUN mkdir /vol/janeway/kubernetes
COPY autorun.sh /vol/janeway/docker/
COPY initialize-janeway.sh /vol/janeway/docker/
# Copy auto-install auto-update janeway install command into django commands
COPY ./commands/ /vol/janeway/src/utils/management/commands/
# Copy additional shared functions into the utils folder
COPY k8s_shared.py /vol/janeway/src/utils/
# Copy custom themes into the themes folder & remove the gitignore
COPY ./custom-themes/ /vol/janeway/src/themes/
RUN rm -f /vol/janeway/src/themes/.gitignore
# Copy code that extracts the default journal domain
COPY extract_default_journal_domain.py /usr/local/bin/
# Create Janeway logs directory. This was done due to some errors and should
# be corrected another way in the future.
RUN mkdir -p /vol/janeway/logs
RUN touch /vol/janeway/logs/janeway.logs

# Delete everything in the temp directory
WORKDIR /vol/janeway
RUN rm -r /tmp/janeway

# Generate python bytecode files - they cannot be generated on the k8s because
# Read-Only-Filesystems is enabled.
RUN source ${VENV_PATH}/bin/activate && python3 -m compileall .

# Create user to run the janeway application
RUN adduser janeway
RUN groupmod -g 9950 janeway
# Make Janeway a sudoer
RUN adduser janeway sudo

# Static dir and media dir are added are specified in case they're not in /vol/janeway
RUN mkdir -p ${STATIC_DIR} ${MEDIA_DIR}

# Grant permissions to the user
# ONLY PERMISSIONS FOR NON-MOUNTED VOLUMES APPLY TO KUBERNETES. For example, /vol/janeway
# is stored on the image, while /db will be mounted with a Kubernetes Persistent Volume. 
# You must set the permissions for mounted volumes in Kubernetes. This is done in the 
# app spec. To grant access to www-data for all mounted volumes, set securityContext.fsGroup
# equal to 33 (which is the group ID for www-data).
RUN mkdir -p /var/www/janeway/collected-static /var/www/janeway/media \
    /var/www/janeway/additional-plugins /var/www/janeway/logs
RUN chown --recursive janeway:janeway /vol/janeway /var/www/janeway /tmp
# Allow www-data to use cron
RUN usermod -aG crontab janeway
# Allow this file to be run
RUN chmod +x /vol/janeway/docker/autorun.sh /vol/janeway/docker/initialize-janeway.sh
# Set the active user to the apache default
USER janeway

ENV JANEWAY_SETTINGS_MODULE=core.prod_settings

WORKDIR /vol/janeway
CMD ["/vol/janeway/docker/autorun.sh"]
