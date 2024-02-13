# Based on python 3.8 Debian
FROM python:3.8
SHELL ["/bin/bash", "-c"]

# Install debian dependencies
#------------------------------------------------------
RUN apt-get update
# These may not all be neccesary. Some of them were 
# copied from an outdated config file. 
RUN apt-get install -y gettext apache2 libxml2-dev \
  libxslt1-dev python3-dev zlib1g-dev  \
  libffi-dev libssl-dev libjpeg-dev apache2-utils \
  apache2-dev pandoc pylint cron

# Set environment variabes. 
#------------------------------------------------------

# Settings overwriteable with Kubernetes
#--
# Set the Janeway Config File
ENV JANEWAY_SETTINGS_MODULE=core.prod_settings
# Set the domain name for apache. This will be the servername
# and the WSGI Daemon Process and WSGI Process Group names as well
ENV APACHE_DOMAIN=localhost
#
# FOR THE FOLLOWING 2 SETTINGS, these should be folders that are only
# used for these purposes. There should be nothing in them by default,
# and they shouldn't be used by other programs. For instance, MEDIA_DIR
# can't be /media, as that's a pre-existing folder used by Debian. 
#
# Set the static directory. This is the default location, and it can
# be changed. 
ENV STATIC_DIR=/vol/janeway/src/collected-static
# Set the media directory. This is the default location, and it can 
# be changed
ENV MEDIA_DIR=/vol/janeway/src/media

# Settings you can't overwrite with Kubernetes
#--
# The path for the virtual environment
ENV VENV_PATH=/opt/venv
# Append the location of the virtual environment to the path
# so that Apache can find the neccesary packages. This
# makes it so that python-home is not neccesary
ENV PATH="$VENV_PATH/bin:$PATH"
# Set if the orchestrator is kuberentes. If set to true, the /src/static
# folder will be copied into /src/temp_static. Kubernetes will then copy
# this folder back into static, which will have a non-persistant volume 
# mount (emptyDir) (Not finished)
# ENV ORCHESTRATOR_IS_KUBERNETES=true

# Create the virtual environment
RUN python3 -m venv $VENV_PATH

# Install Python required packages
WORKDIR /vol/janeway
ADD ./janeway/requirements.txt /vol/janeway
RUN source ${VENV_PATH}/bin/activate && pip3 install -r requirements.txt
RUN source ${VENV_PATH}/bin/activate && pip3 install mod_wsgi
# Don't generate pycache files for the Janeway installation internally -
# That's why its not with the other ENV Variables - I'm allowing
# it for the pip3 install but not Janeway
ENV PYTHONDONTWRITEBYTECODE=1

# Add the rest of the source code
COPY ./janeway/src /vol/janeway/src
COPY prod_settings.py /vol/janeway/src/core
COPY wsgi.py /vol/janeway/src/core
COPY ./janeway/setup_scripts /vol/janeway/setup_scripts
COPY ./plugins/pandoc_plugin /vol/janeway/src/plugins/pandoc_plugin
COPY ./plugins/typesetting /vol/janeway/src/plugins/typesetting
# move the static files into temp-static 
# for kubernetes to move to a volume mount (Not finished)

# Generate python bytecode files
RUN source ${VENV_PATH}/bin/activate && python3 -m compileall /vol/janeway

# Grant permissions to the www-data user & the www-data group, which are the default
# user and group for apache
# Static dir and media dir are added are specified in case they're not in /vol/janeway
RUN mkdir /var/run/apache2 ${STATIC_DIR} ${MEDIA_DIR} 
# ONLY PERMISSIONS FOR NON-MOUNTED VOLUMES APPLY TO KUBERNETES. For example, /vol/janeway
# is stored on the image, while /db will be mounted with a Kubernetes Persistent Volume. 
# You must set the permissions for mounted volumes in Kubernetes. This is done in the 
# app spec. To grant access to www-data for all mounted volumes, set securityContext.fsGroup
# equal to 33 (which is the group ID for www-data).
RUN chown -R www-data:www-data /vol/janeway /etc/apache2 \
  /var/lib/apache2 /var/log/apache2 /var/run/apache2 \
  ${STATIC_DIR} ${MEDIA_DIR}
# Allow www-data to use cron
RUN usermod -aG crontab www-data
# Set the active user to the apache default
USER www-data

WORKDIR /etc/apache2/sites-available
# Move the apache configuration (called 000-janeway.conf) to the location for apache sites
ADD 000-janeway.conf .
# Deactivate the default apache site and enable janeway. Also enable rewrite rules.
RUN a2dissite 000-default && a2ensite 000-janeway.conf && a2enmod rewrite
WORKDIR /etc/apache2/
# Replace the ports.conf so apache listens on the right port
RUN rm ports.conf 
ADD ports.conf .

# Set the working directory back to the code repo for convenience
WORKDIR /vol/janeway
RUN cp src/core/janeway_global_settings.py src/core/settings.py

# YOU MUST INSTALL JANEWAY BEFORE THE SITE WILL WORK. YOU CAN DO THIS BY EXEC-ING INTO THE CONTAINER AND
# RUNNING /vol/janeway/src/manage.py install_janeway. This only needs to be done once. 

ENV APACHE_PORT=8000
EXPOSE ${APACHE_PORT}
STOPSIGNAL SIGINT
ENTRYPOINT ["/usr/sbin/apache2ctl"]
# Runs apache in the forground so docker doesn't immediately exit
CMD ["-D", "FOREGROUND"]
