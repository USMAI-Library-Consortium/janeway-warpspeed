#!/bin/bash
set -e

/vol/janeway/docker/initialize-janeway.sh 2>&1

cd /vol/janeway/src
/opt/venv/bin/gunicorn --access-logfile - --error-logfile - --bind unix:/tmp/janeway.sock core.wsgi:application