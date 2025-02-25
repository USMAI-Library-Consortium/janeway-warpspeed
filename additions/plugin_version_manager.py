import os
import subprocess
import json

from django.conf import settings # type: ignore

class PluginVersionManager:
    
    def __init__(self, plugin_version_file: str):
        try:
            with open(plugin_version_file, "r") as f:
                self.plugin_versions = json.load(f)
        except FileNotFoundError:
            print(f"Plugins File not found. Creating...")
            with open(plugin_version_file, "w") as f:
                json.dump({}, f)
                self.plugin_versions = {}

        self.plugin_version_file = plugin_version_file

    def get_plugin_action_requirement(self, plugin_name: str):
        """Returns what action the program should take on the plugin. This
        could be install, update, or nothing.
        
        :param plugin_name: The name of the plugin, corresponding to the name of the 
        directory it lives in when cloned.
        :type plugin_name: str
        :return: 'install' | 'update' | None
        :rtype: str | None"""
        installed_version = self._check_installed_plugin_version(plugin_name)
        incoming_version = self._check_incoming_plugin_version(plugin_name)

        if not installed_version: 
            print(f"Plugin {plugin_name} needs to be installed.")
            return "install"
        
        # See if existing version is an ancestor of the incoming version
        plugin_path = self._get_plugin_directory(plugin_name)
        comparison_result = subprocess.run(["git", "merge-base", "--is-ancestor", installed_version, incoming_version], cwd=plugin_path, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            comparison_result.check_returncode()
        except subprocess.CalledProcessError:
            print("ERROR: Incoming plugin is older than the existing plugin - keeping current version.")
            if comparison_result.stderr:
                print(comparison_result.stderr)
            return None
        
        # Now, check if the versions are the same
        is_newer_version_result = subprocess.run(["git", "rev-list", f"{installed_version}...{incoming_version}"], cwd=plugin_path, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        is_newer_version_result.check_returncode()
        version_difference = len(is_newer_version_result.stdout.strip().split())
        newer_version_incoming = version_difference != 0
        
        if newer_version_incoming:
            print(f"Plugin {plugin_name} needs to be updated.")
            return 'update'
        else:
            print(f"Plugin {plugin_name} does not need to be updated.")
            return None
    
    def write_plugin_version(self, plugin_name: str):
        """Writes or overwrites a plugin version. Will save this to the file.
        
        :param plugin_name: The name of the plugin, corresponding to the name of the 
        directory it lives in when cloned.
        :type plugin_name: str
        :return: None"""
        self.plugin_versions[plugin_name] = self._check_incoming_plugin_version(plugin_name)
        with open (self.plugin_version_file, "w") as f:
            json.dump(self.plugin_versions, f)

    @staticmethod
    def _get_plugin_directory(plugin_name: str):
        """Gets the directory path of the plugin.
        
        :param plugin_name: The name of the plugin, corresponding to the name of the 
        directory it lives in when cloned.
        :type plugin_name: str
        :return: The directory path of the plugin
        :rtype: str"""
        return os.path.join(settings.BASE_DIR, "plugins", plugin_name)

    def _check_installed_plugin_version(self, plugin_name: str):
        """Checks the version of the currently installed plugin, if
        that plugin is installed.
        
        :param plugin_name: The name of the plugin, corresponding to the name of the 
        directory it lives in when cloned.
        :type plugin_name: str
        :return: The commit id of the installed Plugin, if installed, otherwise None
        :rtype: str | None"""
        return self.plugin_versions.get(plugin_name, None)

    def _check_incoming_plugin_version(self, plugin_name: str):
        """Checks the commit ID of an incoming plugin.
        
        :param plugin_name: The name of the plugin, corresponding to the name of the 
        directory it lives in when cloned.
        :type plugin_name: str
        :return: The commit id of the plugin.
        :rtype: str"""
        path = self._get_plugin_directory(plugin_name)
        
        # Get the commit ID
        result = subprocess.run(["git", "rev-parse", "HEAD"], cwd=path, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        result.check_returncode() # Throws a CalledProcessError
        return result.stdout.strip()
