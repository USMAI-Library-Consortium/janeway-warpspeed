import os
from .janeway_global_settings import LOGGING # type: ignore

# Set the static and media directories 
STATIC_ROOT = "/var/www/janeway/collected-static"
MEDIA_ROOT = "/var/www/janeway/media"

# Enable ORCID to be configured by Kubernetes
ENABLE_ORCID = os.getenv("JANEWAY_ENABLE_ORCID", "False").lower() in ("true", "1", "yes")
EMAIL_USE_TLS = os.getenv("JANEWAY_EMAIL_USE_TLS", "False").lower() in ("true", "1", "yes")
DEBUG = os.getenv("DJANGO_DEBUG", "False").lower() in ("true", "1", "yes")

ALLOWED_HOSTS = [
    os.environ.get('JANEWAY_PRESS_DOMAIN')
]

if DEBUG:
    ALLOWED_HOSTS.append("127.0.0.1")
    ALLOWED_HOSTS.append("localhost")
    ALLOWED_HOSTS.append("janeway")

journal_domains = os.getenv("JANEWAY_JOURNAL_DOMAINS", "").split(",")
if journal_domains:
    for domain in journal_domains:
        ALLOWED_HOSTS.append(journal_domains)

CSRF_TRUSTED_ORIGINS=[
    os.environ.get('JANEWAY_PRESS_DOMAIN_SCHEME') + os.environ.get('JANEWAY_PRESS_DOMAIN')
]

if DEBUG:
    CSRF_TRUSTED_ORIGINS.append("http://127.0.0.1")
    CSRF_TRUSTED_ORIGINS.append("http://localhost")
    CSRF_TRUSTED_ORIGINS.append("http://janeway")

journal_domains = os.getenv("JANEWAY_JOURNAL_DOMAINS", "").split(",")
journal_domain_schemes = os.getenv("JANEWAY_JOURNAL_DOMAIN_SCHEMES", "").split(",")
if journal_domains:
    for i, domain in enumerate(journal_domains):
        if domain:
            CSRF_TRUSTED_ORIGINS.append(journal_domain_schemes[i] + journal_domains[i])

LOGGING['handlers']['log_file']['filename'] = "/var/www/janeway/logs/janeway.log"