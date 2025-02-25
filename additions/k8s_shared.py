import os

# Kubernetes doesn't allow boolean environment variables, they're set as 
# strings. Python doesn't seem to be able to convert them to booleans 
# automatially, so every boolean value in janeway_global_settings that we
# want to set in Kubernetes needs to be converted from a string to a boolean.
#
# It also works in Docker because it will return true even if it receives a
# boolean

def convert_to_bool(var_name: str) -> bool:
    """Converts an environment variable to a boolean."""
    val = os.environ.get(var_name, False)
    if val and val.upper() == "TRUE": return True
    return False