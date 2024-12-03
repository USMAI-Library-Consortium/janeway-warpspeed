# Using / Configuring this Docker Image

This dockerimage is designed to be used pretty much as-is, and if done correctly shouldn't need to be forked and modified. Important setup and configuration options use environment variables, so you should be able to set up janeway just the way you want it in your production environment using those. 

This docker image is currently designed to use Postgres.

## Required environment variables:
1. DB_HOST: Hostname of your Postgres DB
2. DB_PORT: Postgres DB Port
3. DB_NAME: Name of your db within postgres
4. DB_USER: Name of the postgres user
5. DB_PASSWORD: Password to connect to the postgres DB
6. JANEWAY_PRESS_NAME: Specifies the Press Name to use when installing Janeway
7. JANEWAY_PRESS_DOMAIN: Specifies the Press Domain to use when installing Janeway. Should be the same as the domain name that you give Janeway
8. JANEWAY_PRESS_CONTACT: Specifies the Press Contact email address to use when installing Janeway
9. JANEWAY_JOURNAL_CODE: Specifies the Journal Code to use when installing Janeway
10. JANEWAY_JOURNAL_NAME: Specifies the Journal Name to use when installing Janeway 
11. INSTALL_TYPESETTING_PLUGIN: Whether to install the typesetting plugin - TRUE or FALSE
12. INSTALL_PANDOC_PLUGIN: Whether to install the pandoc plugin - TRUE or FALSE

## Optional environment variables
1. JANEWAY_JOURNAL_DESCRIPTION
2. JANEWAY_JOURNAL_DOMAIN