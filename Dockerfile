FROM python:3.11
SHELL ["/bin/bash", "-c"]

# ----------------------- DEBIAN DEPENDENCIES -----------------------
RUN apt-get update
RUN apt-get install -y gettext pandoc cron postgresql-client \
    libxml2-dev libxslt1-dev zlib1g-dev libffi-dev \
    libssl-dev libjpeg-dev


# --------------- ARGUMENTS FOR BUILDING THE IMAGE -------------------
ARG CLONE_REPOSITORY_URL=https://github.com/openlibhums/janeway.git
ARG CLONE_TAG_VERSION=v1.8.0
ARG JANEWAY_VERSION=v1.8.0


# ----------------------- ENVIRONMENT VARIABLES ---------------------
ENV VENV_PATH=/opt/venv
ENV PATH="$VENV_PATH/bin:$PATH"
ENV STATIC_DIR=/var/www/janeway/collected-static
ENV MEDIA_DIR=/var/www/janeway/media
ENV DB_VENDOR="postgres"
ENV PYTHON_ENABLE_GUNICORN_MULTIWORKERS='true'
ENV JANEWAY_VERSION=$JANEWAY_VERSION

# Create the virtual environment
RUN python3 -m venv $VENV_PATH

# ------------------------ JANEWAY MAIN PYTHON DEPENDENCIES ----------------------
# Clone Janeway into tmp directory
WORKDIR /tmp
RUN git clone ${CLONE_REPOSITORY_URL}
RUN cd janeway && git switch --detach ${CLONE_TAG_VERSION}

# Install Python required packages
RUN mkdir -p /vol/janeway/
RUN cp ./janeway/requirements.txt /vol/janeway
WORKDIR /vol/janeway
RUN source ${VENV_PATH}/bin/activate && pip3 install -r requirements.txt
RUN source ${VENV_PATH}/bin/activate && pip3 install 'gunicorn>=26.0.0,<27.0.0'

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
# Copy code that extracts the default journal domain
COPY extract_default_journal_domain.py /usr/local/bin/
# Create Janeway logs directory. This was done due to some errors and should
# be corrected another way in the future.
RUN mkdir -p /vol/janeway/logs
RUN touch /vol/janeway/logs/janeway.logs

# This is so our forked Janeway repo can also store our desired plugins. You will
# likely want to extend our open-source Janeway image and clone the plugins in
# that Dockerfile rather than re-build the base image with a custom fork.
# Make available plugins directory if does not exist
RUN mkdir -p /vol/janeway/src/available-plugins
RUN mkdir -p available-plugins
# Copy included plugins into available plugins directory
RUN cp -r available-plugins/. /vol/janeway/src/available-plugins

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
