import os

from django.core.management.base import BaseCommand # type: ignore
from django.core.management import call_command # type: ignore
from utils.k8s_shared import convert_to_bool # type: ignore

class Command(BaseCommand):
    """
    Performs a standard update procedure for the Janeway application.
    """

    help = "Performs a standard update procedure for the Janeway application."

    def add_arguments(self, parser):
        pass

    def handle(self, *args, **options):
        """Updates Janeway

        :param args: None
        :param options: None
        :return: None
        """
        print("Starting updater...")
        call_command("migrate")
        call_command("build_assets")
        call_command("collectstatic", interactive=False)
        call_command("load_default_settings")
        os.system("python3 src/manage.py update_repository_settings")
        call_command("manage_plugins")
        call_command("update_translation_fields")
        call_command("clear_cache")

        if convert_to_bool("INSTALL_CRON"):
            print("Installing")
            try:
                call_command('install_cron')
            except FileNotFoundError:
                print("Error Installing cron")
                self.stderr.write("Error Installing cron")
        else:
            print("Internal Cron installation disabled.")
            
        call_command("populate_history", "cms.Page", "comms.NewsItem", "repository.Repository")
