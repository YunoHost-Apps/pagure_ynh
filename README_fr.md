# Pagure pour YunoHost

[![Niveau d'intégration](https://dash.yunohost.org/integration/pagure.svg)](https://dash.yunohost.org/appci/app/pagure) ![](https://ci-apps.yunohost.org/ci/badges/pagure.status.svg) ![](https://ci-apps.yunohost.org/ci/badges/pagure.maintain.svg)  
[![Installer Pagure avec YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=pagure)

*[Read this readme in english.](./README.md)*
*[Lire ce readme en français.](./README_fr.md)*

> *Ce package vous permet d'installer Pagure rapidement et simplement sur un serveur YunoHost.
Si vous n'avez pas YunoHost, regardez [ici](https://yunohost.org/#/install) pour savoir comment l'installer et en profiter.*

## Vue d'ensemble



**Version incluse :** 5.13.3~ynh1

**Démo :** https://pagure.io

## Avertissements / informations importantes

* The admin you choose during the instllation has been added to the PAGURE_ADMIN_USERS
* After installation, you must create an account with the same username

## Documentations et ressources

* Site officiel de l'app : https://pagure.io/pagure
* Documentation officielle de l'admin : https://docs.pagure.org/pagure/
* Dépôt de code officiel de l'app : https://pagure.io/pagure
* Documentation YunoHost pour cette app : https://yunohost.org/app_pagure
* Signaler un bug : https://github.com/YunoHost-Apps/pagure_ynh/issues

## Informations pour les développeurs

Merci de faire vos pull request sur la [branche testing](https://github.com/YunoHost-Apps/pagure_ynh/tree/testing).

Pour essayer la branche testing, procédez comme suit.
```
sudo yunohost app install https://github.com/YunoHost-Apps/pagure_ynh/tree/testing --debug
ou
sudo yunohost app upgrade pagure -u https://github.com/YunoHost-Apps/pagure_ynh/tree/testing --debug
```

**Plus d'infos sur le packaging d'applications :** https://yunohost.org/packaging_apps