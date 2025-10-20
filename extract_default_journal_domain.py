import os

if __name__ == "__main__":
    """
    Here's we're returning the FIRST journal domain in the provided 
    JANEWAY_JOURNAL_DOMAINS, if present. This will be used by the default
    journal when installing Janeway. It will be called by a bash script.
    """
    janeway_journal_domains = os.getenv("JANEWAY_JOURNAL_URLS", "").split(",")

    print(janeway_journal_domains[0] if janeway_journal_domains else "")