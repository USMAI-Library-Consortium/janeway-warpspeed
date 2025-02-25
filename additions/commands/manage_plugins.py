import os
import shutil
from importlib import import_module

from django.core.management.base import BaseCommand # type: ignore
from django.core.management import call_command # type: ignore
from utils.k8s_shared import convert_to_bool # type: ignore
from core import plugin_loader # type: ignore
from core.plugin_version_manager import PluginVersionManager # type: ignore
from django.conf import settings # type: ignore

class Command(BaseCommand):
    """
    Installs or upgrades plugins based on environment variables.
    """

    help = "Installs or upgrades plugins based on environment variables."

    def add_arguments(self, parser):
        pass

    def handle(self, *args, **options):
        """Installs or upgrades plugins based on environment variables.

        :param args: None
        :param options: dict
        :return: None
        """
        print("Managing plugins...")

        # Install homepage apps - this will not run within the install_plugins
        # command unless we install all plugins so I'm doing it here manually
        homepage_dirs = plugin_loader.get_dirs(
            os.path.join('core', 'homepage_elements'),
        )
        for homepage_plugin in homepage_dirs:
            print('Checking plugin {0}'.format(homepage_plugin))
            plugin_module_name = "core.homepage_elements.{0}.plugin_settings".format(homepage_plugin)
            plugin_settings = import_module(plugin_module_name)
            plugin_settings.install()

        # Install/upgrade whichever plugins the user requests
        pvm = PluginVersionManager(os.path.join(settings.STATE_DATA_DIR, 'plugin_versions.json'))
        plugin_location = os.path.join(settings.BASE_DIR, "plugins")
        paths = os.listdir(plugin_location)
        for available_plugin_name in paths:
            base_plugin_name_for_env = available_plugin_name.removesuffix("_plugin")
            install_plugin_env_name = f"INSTALL_{base_plugin_name_for_env.upper()}_PLUGIN"

            if convert_to_bool(install_plugin_env_name):
                action = pvm.get_plugin_action_requirement(available_plugin_name)

                if action: 
                    call_command("install_plugins", plugin_name=available_plugin_name)
                    pvm.write_plugin_version(available_plugin_name)