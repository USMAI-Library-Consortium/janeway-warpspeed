import os #type: ignore
import shutil #type: ignore
import sass #type: ignore
from jsmin import jsmin #type: ignore

from django.conf import settings #type: ignore
from django.core.management import call_command #type: ignore

from journal import models as journal_models #type: ignore

def process_scss():
    """Compiles SCSS into CSS in the Static Assets folder"""
    # File dirs
    app_scss_file = os.path.join(settings.BASE_DIR, "themes/usmai/assets/scss/app.scss")
    app_css_file = os.path.join(settings.BASE_DIR, "static/usmai/css/app.css")

    compiled_css_from_file = sass.compile(filename=app_scss_file)

    # Open the CSS file and write into it
    write_file = open(app_css_file, "w", encoding="utf-8")
    write_file.write(compiled_css_from_file)

def copy_files(src_path, dest_path):
    """
    :param src_path: The source folder for copying
    :param dest_path: The destination these files/folders should be copied to
    :return: None
    """
    if not os.path.exists(src_path):
        os.makedirs(src_path)

    files = os.listdir(src_path)

    for file_name in files:
        full_file_name = os.path.join(src_path, file_name)
        if os.path.isfile(full_file_name):
            shutil.copy(full_file_name, dest_path)
        else:
            dir_dest = os.path.join(dest_path, file_name)
            if os.path.exists(dir_dest):
                shutil.rmtree(os.path.join(dir_dest))
            shutil.copytree(full_file_name, dir_dest)


def copy_file(source, destination):
    """
    :param source: The source of the folder for copying
    :param destination: The destination folder for the file
    :return:
    """

    destination_folder = os.path.join(settings.BASE_DIR, os.path.dirname(destination))

    if not os.path.exists(destination_folder):
        os.mkdir(destination_folder)

    shutil.copy(
        os.path.join(settings.BASE_DIR, source),
        os.path.join(settings.BASE_DIR, destination),
    )


def process_images():
    """Processes images from the compile folder into Static Assets"""
    image_path = os.path.join(settings.BASE_DIR, "themes/usmai/assets/img/")
    static_images = os.path.join(settings.BASE_DIR, "static/usmai/img/")

    copy_files(image_path, static_images)

def create_paths():
    base_path = os.path.join(settings.BASE_DIR, "static", "usmai")
    folders = ["css", "js", "fonts", "img"]

    for folder in folders:
        os.makedirs(os.path.join(base_path, folder), exist_ok=True)

    # test if the journal CSS directory exists and create it if not
    override_css_dir = os.path.join(settings.BASE_DIR, "static", "usmai", "css")
    os.makedirs(override_css_dir, exist_ok=True)

    return override_css_dir


def build():
    _ = create_paths()
    print("Processing SCSS")
    process_scss()
    process_images()
    call_command("collectstatic", "--noinput")
