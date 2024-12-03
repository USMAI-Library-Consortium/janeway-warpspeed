import os

# Set the static and media directories 
STATIC_ROOT = os.environ['STATIC_DIR']
MEDIA_ROOT = os.environ['MEDIA_DIR']

# Kubernetes doesn't allow boolean environment variables, they're set as 
# strings. Python doesn't seem to be able to convert them to booleans 
# automatially, so every boolean value in janeway_global_settings that we
# want to set in Kubernetes needs to be converted from a string to a boolean.
#
# It also works in Docker because it will return true even if it receives a
# boolean
def convert_env_to_bool(env: str):
    if env.upper() == 'TRUE' or env == True:
        return True
    else: return False
# Enable ORCID to be configured by Kubernetes
ENABLE_ORCID = convert_env_to_bool(os.environ['JANEWAY_ENABLE_ORCID'])
EMAIL_USE_TLS = convert_env_to_bool(os.environ['JANEWAY_EMAIL_USE_TLS'])