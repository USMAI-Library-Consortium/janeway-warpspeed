# Based on python 3.10 Debian
FROM python:3.10
SHELL ["/bin/bash", "-c"]

# Install debian dependencies
#------------------------------------------------------
RUN apt-get update
RUN apt-get install -y gettext pandoc cron postgresql-client \
    libxml2-dev libxslt1-dev zlib1g-dev lib32z1-dev libffi-dev \
    libssl-dev libjpeg-dev

# Set environment variabes. 
#------------------------------------------------------

# Settings overwriteable with Kubernetes
#--
# Set the Janeway Config File
ENV JANEWAY_SETTINGS_MODULE=core.prod_settings
# Set the media directory. This is the default location, and it can 
# be changed
ENV MEDIA_DIR=/vol/janeway/src/media

# Settings you can't overwrite with Kubernetes
#----------------------------------------------------------
# The path for the virtual environment
ENV VENV_PATH=/opt/venv
# Append the location of the virtual environment to the path
# so that Apache can find the neccesary packages. This
# makes it so that python-home is not neccesary
ENV PATH="$VENV_PATH/bin:$PATH"
# Set the static directory.
ENV STATIC_DIR=/vol/janeway/src/collected-static

# Create the virtual environment
RUN python3 -m venv $VENV_PATH

# Install Python required packages
WORKDIR /vol/janeway
ADD ./janeway/requirements.txt /vol/janeway
RUN source ${VENV_PATH}/bin/activate && pip3 install -r requirements.txt
RUN source ${VENV_PATH}/bin/activate && pip3 install 'gunicorn>=23.0.0,<24.0.0'
# Don't generate pycache files for the Janeway installation internally -
# That's why its not with the other ENV Variables - I'm allowing
# it for the pip3 install but not Janeway
ENV PYTHONDONTWRITEBYTECODE=1

# Add the rest of the source code
COPY ./janeway/src /vol/janeway/src
COPY prod_settings.py /vol/janeway/src/core
COPY ./janeway/setup_scripts /vol/janeway/setup_scripts
COPY run-k8s.sh /vol/janeway/setup_scripts
COPY plugins /tmp

# Generate python bytecode files - they cannot be generated on the k8s because
# Read-Only-Filesystems is enabled.
RUN source ${VENV_PATH}/bin/activate && python3 -m compileall .

# Grant permissions to the www-data user & the www-data group, which are the default
# user and group for apache
# Static dir and media dir are added are specified in case they're not in /vol/janeway
RUN mkdir ${STATIC_DIR} ${MEDIA_DIR} 
# ONLY PERMISSIONS FOR NON-MOUNTED VOLUMES APPLY TO KUBERNETES. For example, /vol/janeway
# is stored on the image, while /db will be mounted with a Kubernetes Persistent Volume. 
# You must set the permissions for mounted volumes in Kubernetes. This is done in the 
# app spec. To grant access to www-data for all mounted volumes, set securityContext.fsGroup
# equal to 33 (which is the group ID for www-data).
RUN chown -R www-data:www-data /vol/janeway ${STATIC_DIR} ${MEDIA_DIR} /tmp/plugins
# Allow www-data to use cron
RUN usermod -aG crontab www-data
# Set the active user to the apache default
USER www-data

# Run image-side janeway setup info.
RUN source ${VENV_PATH}/bin/activate && python3 src/manage.py collectstatic --no-input
RUN source ${VENV_PATH}/bin/activate && python3 src/manage.py build_assets
RUN source ${VENV_PATH}/bin/activate && python3 src/manage.py compilemessages

# Set the working directory back to the code repo for convenience
RUN cp src/core/janeway_global_settings.py src/core/settings.py

ENTRYPOINT ["/vol/janeway/setup_scripts/run-k8s.sh"]
