#!/bin/sh
set -e

echo "Waiting for /tmp/janeway.sock to appear..."
until [ -S /tmp/janeway.sock ]; do
    echo "Nginx is waiting for Janeway to be ready..."
    sleep 3
done

echo "Janeway is ready. Starting Nginx..."
exec nginx -g "daemon off;"