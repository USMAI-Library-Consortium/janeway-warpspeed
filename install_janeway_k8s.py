import os

from django.conf import settings
from django.core.management.base import BaseCommand
from django.core.management import call_command
from django.db import transaction
from django.utils import translation
from django.core.exceptions import ImproperlyConfigured

from press import models as press_models # type: ignore
from journal import models as journal_models # type: ignore
from utils.install import ( # type: ignore
        update_issue_types,
        update_settings,
        update_xsl_files,
)
from utils import shared # type: ignore

ROLES_RELATIVE_PATH = 'utils/install/roles.json'

class Command(BaseCommand):
    """
    Installs a press and oe journal for Janeway.
    """

    help = "Installs a press and oe journal for Janeway."

    def add_arguments(self, parser):
        pass

    def handle(self, *args, **options):
        """Installs Janeway

        :param args: None
        :param options: dict
        :return: None
        """

        # As of v1.4 USE_I18N must be enabled.
        if not settings.USE_I18N:
            raise ImproperlyConfigured("USE_I18N must be enabled from v1.4 of Janeway.")

        call_command('migrate')
        translation.activate('en')
        with transaction.atomic():
            press = press_models.Press.objects.first()
            if not press:
                press = press_models.Press()
                press.name = os.getenv("JANEWAY_PRESS_NAME", default='Press')
                press.domain = os.getenv("JANEWAY_PRESS_DOMAIN", default='localhost')
                press.main_contact= os.getenv("JANEWAY_PRESS_CONTACT", default='dev@noemail.com')
                press.save()

            update_xsl_files()
            update_settings()

            journal = journal_models.Journal()
            journal.code = os.getenv("JANEWAY_JOURNAL_CODE", default='Journal')
            journal.domain = os.getenv("JANEWAY_JOURNAL_DOMAIN", default='')
            journal.save()

            print("Installing issue types fixtures... ", end="")
            update_issue_types(journal, management_command=False)
            print("[okay]")
            print("Installing role fixtures")

            roles_path = os.path.join(settings.BASE_DIR, ROLES_RELATIVE_PATH)
            print('Installing default settings')
            call_command('load_default_settings')
            call_command('loaddata', roles_path)
            journal.name = os.getenv("JANEWAY_JOURNAL_NAME", default='Test Journal')
            journal.description = os.getenv("JANEWAY_JOURNAL_DOMAIN", default='')
            journal.save()
            journal.setup_directory()

            print("Journal #1 has been saved.\n")

            call_command('show_configured_journals')
            print("Installing plugins.")
            call_command('install_plugins')
            print("Installing Cron jobs")
            try:
                call_command('install_cron')
            except FileNotFoundError:
                self.stderr.write("Error Installing cron")

            call_command('createsuperuser')

            print('Open your browser to your new journal domain '
                '{domain}/install/ to continue this setup process.'.format(
                    domain=journal.domain
                        if journal.domain
                        else '{}/{}'.format(
                            press.domain, journal.code)
                )
            )

            if options['dry_run'] is True:
                print("This was a --dry-run, rolling back...")
                raise SystemExit()

        # finally, clear the cache
        shared.clear_cache()
        try:
            columns = os.get_terminal_size().columns
            if columns <= 144:
                print(JANEWAY_ASCII_SMALL)
            else:
                print(JANEWAY_ASCII)
        except Exception:
            print(JANEWAY_ASCII_SMALL)


JANEWAY_ASCII = """


                                                                ################
                                                           #######            #######
                                                       #####                        #####
                                                    ####                                ####
                                                  ####                                    ####
                                                ###                                          ###
                                              ####                                            %###
                                             ###                                                ###
                                            ###                                                  ###
                                           ##                                                      ##
                                          ##                                                        ##
                                         ###                                                         ##

            ####        ####          ####             ###   #################  ####           ####           ####    ####   #####         #####
            ####       ######         ######           ###   #################   ####         ######         ####    ######    ####       #####
            ####      ########        ########         ###   ####                 ####       ########       ####    ########    ####     ####
            ####     ####  ####       #### #####       ###   ####                 ####      ####  ###      ####    ###%  ####    ####   ####
            ####    ####    ####      ####   #####     ###   ###############       ####     ###   ####     ####   ####    ####    #### ####
            ####   ####      ###      ####     #####   ###   ###############        ####   ####    ####   ####   ####      ###     #######
####        ####  ###############     ####       ####% ###   ####                    #### ####      ###  ####   ###############      ###
#####      ####   ################    ####        ########   ####                     ### ###        #######    ################     ###
 #############   #####        #####   ####          ######   #################        #######        ######    #####        #####    ###
    #######     ####            ####  ####            ####   #################         #####          #####   ####            ####   ###

                                         ###                                                         ##
                                          ##                                                        ##
                                           ##                                                      ##
                                            ###                                                  ###
                                             ###                                                ###
                                              ####                                             ###
                                                ###                                          ###
                                                  ####                                    ####
                                                    ####                                ####
                                                       #####                        #####
                                                           #######            #######
                                                                ################


"""

JANEWAY_ASCII_SMALL = """
                                  @@@@@@@@@@@@
                              @@@              @@@
                            @                      @
                          @                          @
                        @@                            @@
                       @@                              @@

       @@    @@@     @@@      @@  @@@@@@@@@  @@     @@@      @@  @@@  @@     @@
       @@   @@ @@    @@@@@    @@  @@          @@    @@@@    @@  @@ @@  @@@  @@
       @@  @@   @@   @@  @@@  @@  @@@@@@@@    @@@  @@  @@  @@  @@   @@   @@@@
@@    @@@ @@@@@@@@@  @@    @@@@@  @@           @@ @@    @@@@  @@@@@@@@@   @@
 @@@@@@@ @@@     @@@ @@      @@@  @@@@@@@@@     @@@     @@@@ @@@     @@@  @@

                       @@                              @@
                        @@                            @@
                          @                          @
                            @                      @
                              @@@              @@@
                                  @@@@@@@@@@@@
"""
