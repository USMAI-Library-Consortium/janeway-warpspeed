import os
from urllib.parse import urlparse

if __name__ == "__main__":
    janeway_press_domain = os.getenv("JANEWAY_PRESS_URL", "")
    print(urlparse(janeway_press_domain).netloc)