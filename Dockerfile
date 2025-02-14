# Based on python 3.10 Debian
FROM python:3.10
SHELL ["/bin/bash", "-c"]

# Install debian dependencies
#------------------------------------------------------
RUN apt-get update
RUN apt-get install -y gettext pandoc cron postgresql-client \
    libxml2-dev libxslt1-dev zlib1g-dev libffi-dev \
    libssl-dev libjpeg-dev nginx

# Set environment variabes. 
#------------------------------------------------------

ENV VENV_PATH=/opt/venv
ENV PATH="$VENV_PATH/bin:$PATH"
ENV STATIC_DIR=/var/www/janway/collected-static
ENV MEDIA_DIR=/var/www/janeway/media

# Create the virtual environment
RUN python3 -m venv $VENV_PATH

# Install Python required packages
WORKDIR /vol/janeway
RUN mkdir gunicorn
ADD ./janeway/requirements.txt /vol/janeway
RUN source ${VENV_PATH}/bin/activate && pip3 install -r requirements.txt
RUN source ${VENV_PATH}/bin/activate && pip3 install 'gunicorn>=23.0.0,<24.0.0'
# Don't generate pycache files for the Janeway installation internally -
# That's why its not with the other ENV Variables - I'm allowing
# it for the pip3 install but not Janeway
ENV PYTHONDONTWRITEBYTECODE=1

# Add the rest of the source code

# Copy Janeway code
COPY ./janeway/src/ /vol/janeway/src/
# Copy static to temp folder. There's no direct use for this right now, but I'm envisioning a
# possibility of having custom static files that also need to be copied into the /static/ 
# directory to be compiled. In Kubernetes, this requires the static file to be empty to start, 
# so we copy the files from /tmp/static to the src static directory in the run-k8s.sh script. 
COPY ./janeway/src/static/ /tmp/static/
# Copy custom settings file into Janeway
COPY prod_settings.py /vol/janeway/src/core/
# Copy kubernetes install and setup script into Janeway
RUN mkdir /vol/janeway/kubernetes
COPY run-k8s.sh /vol/janeway/kubernetes/
# Copy auto-install auto-update janeway install command into django commands
COPY install_janeway_k8s.py /vol/janeway/src/utils/management/commands/
# Copy all installable plugins into a temp directory, to be installed later
COPY ./plugins/ /tmp/plugins/
# Create nginx directory and copy configuration in there
RUN mkdir -p /etc/nginx
COPY nginx.conf /etc/nginx/
# Create Janeway logs directory
RUN mkdir -p /vol/janeway/logs
RUN touch /vol/janeway/logs/janeway.log
# Required in Docker-Compose, will be overwritten on Kubernetes

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
RUN mkdir -p /var/lib/nginx
RUN chown --recursive janeway:janeway /vol/janeway /var/www/janeway /tmp /var/lib/nginx /var/log/nginx
# Allow www-data to use cron
RUN usermod -aG crontab janeway
# Allow this file to be run
RUN chmod +x /vol/janeway/kubernetes/run-k8s.sh
# Set the active user to the apache default
USER janeway

ENV JANEWAY_SETTINGS_MODULE=core.prod_settings

ENTRYPOINT ["/vol/janeway/kubernetes/run-k8s.sh"]
