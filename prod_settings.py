import os
from urllib.parse import urlparse
from .janeway_global_settings import LOGGING # type: ignore

# Set the static and media directories 
STATIC_ROOT = "/var/www/janeway/collected-static"
MEDIA_ROOT = "/var/www/janeway/media"

# Enable ORCID to be configured by Kubernetes
ENABLE_ORCID = os.getenv("JANEWAY_ENABLE_ORCID", "False").lower() in ("true", "1", "yes")
EMAIL_USE_TLS = os.getenv("JANEWAY_EMAIL_USE_TLS", "False").lower() in ("true", "1", "yes")
DEBUG = os.getenv("DJANGO_DEBUG", "False").lower() in ("true", "1", "yes")

if os.getenv("INSTALLATION_BASE_THEME"):
    INSTALLATION_BASE_THEME = os.getenv("INSTALLATION_BASE_THEME")

# ------------------------------- NETWORKING -------------------------------

press_domain = os.environ.get('JANEWAY_PRESS_URL')
parsed_press_domain = urlparse(press_domain) # Get Netloc from press domain
ALLOWED_HOSTS = [
    parsed_press_domain.netloc
]

CSRF_TRUSTED_ORIGINS=[
    press_domain
]

# Add local values if DEBUG is active.
if DEBUG:
    ALLOWED_HOSTS.append("127.0.0.1")
    ALLOWED_HOSTS.append("localhost")
    ALLOWED_HOSTS.append("janeway")
    CSRF_TRUSTED_ORIGINS.append("http://127.0.0.1")
    CSRF_TRUSTED_ORIGINS.append("http://localhost")
    CSRF_TRUSTED_ORIGINS.append("http://janeway")

journal_domains = os.getenv("JANEWAY_JOURNAL_URLS", "").split(",")
if journal_domains:
    for domain in journal_domains:
        # Parse out components of domain
        parsed_domain = urlparse(domain)

        # Add the netloc to allowed hosts
        if parsed_domain.netloc not in ALLOWED_HOSTS:
            ALLOWED_HOSTS.append(parsed_domain.netloc)

        # Add the full domain to the CSRF_TRUSTED_ORIGINS
        if domain not in CSRF_TRUSTED_ORIGINS:
            CSRF_TRUSTED_ORIGINS.append(domain)

# ------------------------------- LOGGING -------------------------------

LOGGING['handlers']['log_file']['filename'] = "/var/www/janeway/logs/janeway.log"