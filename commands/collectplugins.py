import os
import shutil

from django.conf import settings # type: ignore
from django.core.management.base import BaseCommand # type: ignore

class Command(BaseCommand):
    """
    Collects available and custom plugins into plugins folder.
    """

    help = "Collects available and custom plugins into plugins folder."

    def add_arguments(self, parser):
        pass

    def handle(self, *args, **options):
        """Collects plugins to be used.

        :param args: None
        :param options: dict
        :return: None
        """

        print("Collecting Plugins...")

        def convert_to_bool(var_name: str) -> bool:
            val = os.environ.get(var_name, False)
            if val and val.upper() == "TRUE": return True
            return False

        install_typesetting_plugin = convert_to_bool("INSTALL_TYPESETTING_PLUGIN")
        print(f"Typesetting Plugin Requested: {install_typesetting_plugin}")
        install_pandoc_plugin = convert_to_bool("INSTALL_PANDOC_PLUGIN")
        print(f"Pandoc Plugin Requested: {install_pandoc_plugin}")
        install_customstyling_plugin = convert_to_bool("INSTALL_CUSTOMSTYLING_PLUGIN")
        print(f"Customstyling Plugin Requested: {install_customstyling_plugin}")
        install_portico_plugin = convert_to_bool("INSTALL_PORTICO_PLUGIN")
        print(f"Portico Plugin Requested: {install_portico_plugin}")
        install_imports_plugin = convert_to_bool("INSTALL_IMPORTS_PLUGIN")
        print(f"Imports Plugin Requested: {install_imports_plugin}")
        install_doaj_transporter_plugin = convert_to_bool("INSTALL_DOAJ_TRANSPORTER_PLUGIN")
        print(f"DOAJ Transporter Plugin Requested: {install_doaj_transporter_plugin}")
        install_back_content_plugin = convert_to_bool("INSTALL_BACK_CONTENT_PLUGIN")
        print(f"Back Content Plugin Requested: {install_back_content_plugin}")

        def overwrite_plugin(plugin_name):
            source = f"/vol/janeway/src/available-plugins/{plugin_name}"
            dest = f"/vol/janeway/src/plugins/{plugin_name}"
            if os.path.exists(dest):
                shutil.rmtree(dest)
            shutil.copytree(source, dest)

        installed_plugins = []

        if install_typesetting_plugin:
            overwrite_plugin("typesetting")
            installed_plugins.append("Typesetting")
        if install_pandoc_plugin:
            overwrite_plugin("pandoc_plugin")
            installed_plugins.append("Pandoc")
        if install_customstyling_plugin:
            overwrite_plugin("customstyling")
            installed_plugins.append("Customstyling")
        if install_portico_plugin:
            overwrite_plugin("portico")
            installed_plugins.append("Portico")
        if install_imports_plugin:
            overwrite_plugin("imports")
            installed_plugins.append("Imports")
        if install_doaj_transporter_plugin:
            overwrite_plugin("doaj_transporter")
            installed_plugins.append("DOAJ Transporter")
        if install_back_content_plugin:
            overwrite_plugin("back_content")
            installed_plugins.append("Back Content")

        # Transfer over custom plugins
        for plugin_name in os.listdir("/var/www/janeway/additional-plugins"):
            source = f"/var/www/janeway/additional-plugins/{plugin_name}"
            dest = f"/vol/janeway/src/plugins/{plugin_name}"
            if os.path.exists(dest):
                print(f"Overwriting plugin {plugin_name}, as it is also sepecified in additional-plugins. We are assuming a specific version has been selected.")
                shutil.rmtree(dest)
            print(f"Copying Custom Plugin {plugin_name}")
            installed_plugins.append(f"{plugin_name} (from additional-plugins)")
            shutil.copytree(source, dest)

        os.system("python3 -m compileall /vol/janeway/src/plugins")

        print(f"Plugins Collected: {', '.join(installed_plugins)}")
        print("Done collecting plugins.")