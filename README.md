# pagure_ynh
Pagure, a git centered forge for YunoHost

Due to the usage of RemoteCollection, Pagure can't be use on Debian 8.

It needs a libgit2-dev>=0.22:
https://github.com/libgit2/pygit2/blob/62c70e852da23bcb60e64996f6326a3e2a800469/CHANGELOG.rst#0220-2015-01-16

Stretch has 0.25, but it will wait for YunoHost to be compatible:
https://packages.debian.org/search?keywords=libgit2&searchon=names&suite=all&section=all
