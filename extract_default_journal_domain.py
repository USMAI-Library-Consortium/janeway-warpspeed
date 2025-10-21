import os

if __name__ == "__main__":
    """
    This code returns a Janeway Journal Domain based on an index. It relies
    on the JANEWAY_JOURNAL_DOMAINS and JANEWAY_DEFAULT_JOURNAL_INDEX, and 
    prints either an empty string, or the domain that the index points to.

    It's used for setting the JANEWAY_JOURNAL_DOMAIN variable, which enables
    the default janeway journal install to have it's own domain.
    """
    janeway_journal_domains = os.getenv("JANEWAY_JOURNAL_DOMAINS", "").split(",")

    if janeway_journal_domains:
        janeway_default_journal_index = os.getenv("JANEWAY_DEFAULT_JOURNAL_INDEX", "")

        if janeway_default_journal_index:
            try:
                janeway_default_journal_index = int(janeway_default_journal_index)
                print(janeway_journal_domains[janeway_default_journal_index])
            except ValueError:
                raise ValueError(f"Invalid value for JANEWAY_DEFAULT_JOURNAL_INDEX; {janeway_default_journal_index} cannot be converted to an integer")
            except IndexError:
                raise IndexError(f"Index {janeway_default_journal_index} does not exist in JANEWAY_JOURNAL_DOMAINS")
        else: print("")
    else: print("")
            