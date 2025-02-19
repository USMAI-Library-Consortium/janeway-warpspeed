import os
import shutil
import subprocess

from django.core.management.base import BaseCommand # type: ignore
from django.core.management import call_command # type: ignore

class Command(BaseCommand):
    """
    Collects available and custom plugins into plugins folder.
    """

    help = "Collects available and custom plugins into plugins folder."

    def add_arguments(self, parser):
        pass

    @staticmethod
    def check_if_incoming_plugin_is_newer(existing_plugin: str, incoming_plugin: str, plugin_name: str) -> bool:
        # Handle the case where the incoming plugin is older than the existing one
        result = subprocess.run(["git", "rev-parse", "HEAD"], cwd=existing_plugin, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        result.check_returncode() # Throws a CalledProcessError
        existing_plugin_commit_id = result.stdout.strip()
        result = subprocess.run(["git", "rev-parse", "HEAD"], cwd=incoming_plugin, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        result.check_returncode() # Throws a CalledProcessError
        new_plugin_commit_id = result.stdout.strip()

        comparison_result = subprocess.run(["git", "merge-base", "--is-ancestor", existing_plugin_commit_id, new_plugin_commit_id], cwd=incoming_plugin, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            comparison_result.check_returncode() # Throws error on non-zero status code
            # Incoming plugin is the same or newer than the existing one
        except subprocess.CalledProcessError:
            # Incoming plugin is OLDER than the existing one
            print("ERROR: Incoming plugin is older than the existing plugin - keeping current version.")
            if comparison_result.stderr:
                print(comparison_result.stderr)
            return False
        
        # Check whether the plugin is the same version or is updated
        is_newer_version_result = subprocess.run(["git", "rev-list", f"{existing_plugin_commit_id}...{new_plugin_commit_id}"], cwd=incoming_plugin, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        result.check_returncode()
        version_difference = len(is_newer_version_result.stdout.strip().split())
        newer_version_incoming = version_difference != 0

        if not newer_version_incoming:
            print(f"Plugin {plugin_name} does not need to be updated.")
            return False
        
        print(f"Incoming plugin {plugin_name} is {version_difference} commits ahead of the existing plugin...")
        return True
    
    def overwrite_plugin(self, plugin_name: str) -> str | None:
        """Installs or overwrites a plugin on the condition that this plugin
        is newer than the existing plugin.
        
        Returns the operation that happened (install, update, None)"""
        existing_plugin = f"/vol/janeway/src/plugins/{plugin_name}"
        incoming_plugin = f"/vol/janeway/src/available-plugins/{plugin_name}"
        if os.path.exists(existing_plugin):
            incoming_is_newer = self.check_if_incoming_plugin_is_newer(existing_plugin, incoming_plugin, plugin_name)
            if not incoming_is_newer: return
            
            # Clear it to be overwritten if the incoming plugin is newer than the existing one.
            shutil.rmtree(existing_plugin)
            return_code = "update"
        else:
            return_code = "install"

        # Copy the incoming plugin to the plugins directory
        shutil.copytree(incoming_plugin, existing_plugin)
        return return_code
    
    @staticmethod
    def convert_to_bool(var_name: str) -> bool:
        """Converts an environment variable to a boolean."""
        val = os.environ.get(var_name, False)
        if val and val.upper() == "TRUE": return True
        return False

    def handle(self, *args, **options):
        """Collects plugins to be used.

        :param args: None
        :param options: dict
        :return: None
        """
        print("Collecting Plugins...")

        # Track whether to run the plugin install/upgrade process
        run_install = False
        run_update = False

        # Track which plugins were installed / upgraded
        installed_plugins = []
        updated_plugins = []

        for available_plugin_name in os.listdir("/vol/janeway/src/available-plugins"):
            base_plugin_name_for_env = available_plugin_name.removesuffix("_plugin")
            install_plugin_env_name = f"INSTALL_{base_plugin_name_for_env.upper()}_PLUGIN"

            if self.convert_to_bool(install_plugin_env_name):
                print(f"Built-in plugin {available_plugin_name} is requested to be installed via environment variable.")
                
                if os.path.exists(f"/var/www/janeway/additional-plugins/{available_plugin_name}"):
                    print("You have manually placed this plugin 'additional_plugins', that version will be installed instead.")
                    continue

                action_taken = self.overwrite_plugin(available_plugin_name)
                if action_taken == "install": 
                    installed_plugins.append(available_plugin_name)
                    run_install = True
                if action_taken == "update":
                    updated_plugins.append(available_plugin_name)
                    run_update = True

        # Transfer over custom plugins
        for additional_plugin_name in os.listdir("/var/www/janeway/additional-plugins"):
            existing_plugin = f"/vol/janeway/src/plugins/{additional_plugin_name}"
            incoming_plugin = f"/var/www/janeway/additional-plugins/{additional_plugin_name}"
            
            if os.path.exists(existing_plugin):
                incoming_is_newer = self.check_if_incoming_plugin_is_newer(existing_plugin, incoming_plugin, additional_plugin_name)
                if not incoming_is_newer: return
                
                # Clear the existing plugin to be overwritten if the incoming plugin is newer than the existing one.
                shutil.rmtree(existing_plugin)
                run_update = True
                updated_plugins.append(additional_plugin_name)
            else:
                run_install = True
                installed_plugins.append(f"{additional_plugin_name} (from additional-plugins)")
            
            shutil.copytree(incoming_plugin, existing_plugin)
        
        os.system("python3 -m compileall -q /vol/janeway/src/plugins")
        
        if run_install:
            call_command("install_plugins")
            print(f"Plugins Installed: {', '.join(installed_plugins)}")
        else:
            print("No plugins to install.")
        if run_update:
            call_command("migrate_plugins")
            print(f"Plugins Updated: {', '.join(updated_plugins)}")
        else:
            print("No plugins to update.")