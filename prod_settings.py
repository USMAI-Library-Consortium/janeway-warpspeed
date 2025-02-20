import os
import sys
from utils.k8s_shared import convert_to_bool # type: ignore
from .janeway_global_settings import LOGGING # type: ignore

# Set the static and media directories 
STATIC_ROOT = "/var/www/janeway/collected-static"
MEDIA_ROOT = "/var/www/janeway/media"

# Enable ORCID to be configured by Kubernetes
ENABLE_ORCID = convert_to_bool('JANEWAY_ENABLE_ORCID')
EMAIL_USE_TLS = convert_to_bool('JANEWAY_EMAIL_USE_TLS')

ALLOWED_HOSTS = [
    'localhost',
    '127.0.0.1',
    'janeway',
    os.environ.get('JANEWAY_PRESS_DOMAIN')
]

LOGGING['handlers']['log_file']['filename'] = "/var/www/janeway/logs/janeway.log"