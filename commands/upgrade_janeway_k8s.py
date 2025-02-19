from django.core.management.base import BaseCommand # type: ignore
from django.core.management import call_command # type: ignore

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
        call_command("update_repository_settings")
        call_command("manage_plugins_k8s")
        call_command("update_translation_fields")
        call_command("clear_cache")
        call_command("install_cron")
        call_command("populate_history", "cms.Page", "comms.NewsItem", "repository.Repository")
