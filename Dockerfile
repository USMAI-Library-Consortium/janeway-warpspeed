# Based on python 3.8 Debian
FROM python:3.10
SHELL ["/bin/bash", "-c"]

# Install debian dependencies
#------------------------------------------------------
RUN apt-get update
RUN apt-get install -y gettext pandoc cron

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
# Don't generate pycache files for the Janeway installation internally -
# That's why its not with the other ENV Variables - I'm allowing
# it for the pip3 install but not Janeway
ENV PYTHONDONTWRITEBYTECODE=1

# Add the rest of the source code
COPY ./janeway/src /vol/janeway/src
COPY prod_settings.py /vol/janeway/src/core
COPY ./janeway/setup_scripts /vol/janeway/setup_scripts
# move the static files into temp-static 
# for kubernetes to move to a volume mount (Not finished)

# Generate python bytecode files
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
RUN chown -R www-data:www-data /vol/janeway \
  ${STATIC_DIR} ${MEDIA_DIR}
# Allow www-data to use cron
RUN usermod -aG crontab www-data
# Set the active user to the apache default
USER www-data

# Set the working directory back to the code repo for convenience
WORKDIR /vol/janeway
RUN cp src/core/janeway_global_settings.py src/core/settings.py

# YOU MUST INSTALL JANEWAY BEFORE THE SITE WILL WORK. YOU CAN DO THIS BY EXEC-ING INTO THE CONTAINER AND
# RUNNING /vol/janeway/src/manage.py install_janeway. This only needs to be done once. 

ENTRYPOINT ["/vol/janeway/setup_scripts/install.sh"]
