#!/bin/bash

#=================================================
#
# Redis HELPERS
#
# Point of contact : Jean-Baptiste Holcroft <jean-baptiste@holcroft.fr>
#=================================================

# get the first available redis database
#
# usage: ynh_redis_get_free_db
# | returns: the database number to use
ynh_redis_get_free_db() {
	local result max db
	result=$(redis-cli INFO keyspace)

	# get the num
	max=$(cat /etc/redis/redis.conf | grep ^databases | grep -Eow "[0-9]+")

	db=0
	# default Debian setting is 15 databases
	for i in $(seq 0 "$max")
	do
	 	if ! echo "$result" | grep -q "db$i"
	 	then
			db=$i
	 		break 1
	 		db=-1
 		fi
	done

	test "$db" -eq -1 && ynh_die "No available Redis databases..."

	echo "$db"
}

# Create a master password and set up global settings
# Please always call this script in install and restore scripts
#
# usage: ynh_redis_remove_db database
# | arg: database - the database to erase
ynh_redis_remove_db() {
	local db=$1
	redis-cli -n "$db" flushall
}

ynh_check_global_uwsgi_config () {
	uwsgi --version || ynh_die "You need to add uwsgi (and appropriate plugin) as a dependency"

	cp ../conf/uwsgi-app@.service /etc/systemd/system/uwsgi-app@.service

	# make sure the folder for sockets exists and set authorizations
	mkdir -p /var/run/uwsgi/
	chown root:www-data /var/run/uwsgi/
	chmod -R 775 /var/run/uwsgi/

	# make sure the folder for logs exists and set authorizations
	mkdir -p /var/log/uwsgi/app/
	chown root:www-data /var/log/uwsgi/app/
	chmod -R 775 /var/log/uwsgi/app/
}

# Create a dedicated uwsgi ini file to use with generic uwsgi service
# It will install generic uwsgi.socket and
#
# This will use a template in ../conf/uwsgi.ini
# and will replace the following keywords with
# global variables that should be defined before calling
# this helper :
#
#   __APP__       by  $app
#   __PATH__      by  $path_url
#   __FINALPATH__ by  $final_path
#
# usage: ynh_add_systemd_config
#
# to interact with your service: `systemctl <action> uwsgi-app@app`
ynh_add_uwsgi_service () {
	ynh_check_global_uwsgi_config

	# www-data group is needed since it is this nginx who will start the service
	usermod --append --groups www-data "$app" || ynh_die "It wasn't possible to add user $app to group www-data"

	finaluwsgiini="/etc/uwsgi/apps-available/$app.ini"
	ynh_backup_if_checksum_is_different "$finaluwsgiini"
	cp ../conf/uwsgi.ini "$finaluwsgiini"

	# To avoid a break by set -u, use a void substitution ${var:-}. If the variable is not set, it's simply set with an empty variable.
	# Substitute in a nginx config file only if the variable is not empty
	if test -n "${final_path:-}"; then
		ynh_replace_string "__FINALPATH__" "$final_path" "$finaluwsgiini"
	fi
	if test -n "${path_url:-}"; then
		ynh_replace_string "__PATH__" "$path_url" "$finaluwsgiini"
	fi
	if test -n "${app:-}"; then
		ynh_replace_string "__APP__" "$app" "$finaluwsgiini"
	fi
	ynh_store_file_checksum "$finaluwsgiini"

	chown root: "$finaluwsgiini"

	systemctl daemon-reload
	systemctl enable "uwsgi-app@$app.service"

	# Add as a service
	yunohost service add "uwsgi-app@$app.service" --log "/var/log/uwsgi/app/$app"
}

# Remove the dedicated uwsgi ini file
#
# usage: ynh_remove_systemd_config
ynh_remove_uwsgi_service () {
	finaluwsgiini="/etc/uwsgi/apps-available/$app.ini"
	if [ -e "$finaluwsgiini" ]; then
		systemctl stop "uwsgi-app@$app.service"
		systemctl disable "uwsgi-app@$app.service"
		yunohost service remove "uwsgi-app@$app.service"

		ynh_secure_remove "$finaluwsgiini"
		ynh_secure_remove "/var/log/uwsgi/app/$app"
	fi
}


# LOCAL ADDITION:
# save file locally if not in the cache
#
# Download, check integrity, uncompress and patch the source from app.src
#
# The file conf/app.src need to contains:
#
# SOURCE_URL=Address to download the app archive
# SOURCE_SUM=Control sum
# # (Optional) Program to check the integrity (sha256sum, md5sum...)
# # default: sha256
# SOURCE_SUM_PRG=sha256
# # (Optional) Archive format
# # default: tar.gz
# SOURCE_FORMAT=tar.gz
# # (Optional) Put false if sources are directly in the archive root
# # default: true
# SOURCE_IN_SUBDIR=false
# # (Optionnal) Name of the local archive (offline setup support)
# # default: ${src_id}.${src_format}
# SOURCE_FILENAME=example.tar.gz
#
# Details:
# This helper downloads sources from SOURCE_URL if there is no local source
# archive in /opt/yunohost-apps-src/APP_ID/SOURCE_FILENAME
#
# Next, it checks the integrity with "SOURCE_SUM_PRG -c --status" command.
#
# If it's ok, the source archive will be uncompressed in $dest_dir. If the
# SOURCE_IN_SUBDIR is true, the first level directory of the archive will be
# removed.
#
# Finally, patches named sources/patches/${src_id}-*.patch and extra files in
# sources/extra_files/$src_id will be applied to dest_dir
#
#
# usage: ynh_setup_source dest_dir [source_id]
# | arg: dest_dir  - Directory where to setup sources
# | arg: source_id - Name of the app, if the package contains more than one app
ynh_setup_source_local () {
    local dest_dir=$1
    local src_id=${2:-app} # If the argument is not given, source_id equals "app"

    # Load value from configuration file (see above for a small doc about this file
    # format)
    local src_url=$(grep 'SOURCE_URL=' "$YNH_CWD/../conf/${src_id}.src" | cut -d= -f2-)
    local src_sum=$(grep 'SOURCE_SUM=' "$YNH_CWD/../conf/${src_id}.src" | cut -d= -f2-)
    local src_sumprg=$(grep 'SOURCE_SUM_PRG=' "$YNH_CWD/../conf/${src_id}.src" | cut -d= -f2-)
    local src_format=$(grep 'SOURCE_FORMAT=' "$YNH_CWD/../conf/${src_id}.src" | cut -d= -f2-)
    local src_in_subdir=$(grep 'SOURCE_IN_SUBDIR=' "$YNH_CWD/../conf/${src_id}.src" | cut -d= -f2-)
    local src_filename=$(grep 'SOURCE_FILENAME=' "$YNH_CWD/../conf/${src_id}.src" | cut -d= -f2-)

    # Default value
    src_sumprg=${src_sumprg:-sha256sum}
    src_in_subdir=${src_in_subdir:-true}
    src_format=${src_format:-tar.gz}
    src_format=$(echo "$src_format" | tr '[:upper:]' '[:lower:]')
    if [ "$src_filename" = "" ] ; then
        src_filename="${src_id}.${src_format}"
    fi
    local local_src="/var/cache/yunohost/ynh_setup_source/${YNH_APP_ID}/${src_filename}"

    # if cache file exists and the checksum isn't good, download it again
    # if not, just download the file

    if test -e "$local_src"
    then
    	echo "${src_sum} ${local_src}" | ${src_sumprg} -c --status \
        	|| wget -nv -O $local_src $src_url
    else
    	mkdir -p "/var/cache/yunohost/ynh_setup_source/${YNH_APP_ID}"
    	wget -nv -O $local_src $src_url
    fi
    cp $local_src $src_filename

    # Check the control sum
    echo "${src_sum} ${src_filename}" | ${src_sumprg} -c --status \
        || ynh_die "Corrupt source"

    # Extract source into the app dir
    mkdir -p "$dest_dir"
    if [ "$src_format" = "zip" ]
    then
        # Zip format
        # Using of a temp directory, because unzip doesn't manage --strip-components
        if $src_in_subdir ; then
            local tmp_dir=$(mktemp -d)
            unzip -quo $src_filename -d "$tmp_dir"
            cp -a $tmp_dir/*/. "$dest_dir"
            ynh_secure_remove "$tmp_dir"
        else
            unzip -quo $src_filename -d "$dest_dir"
        fi
    else
        local strip=""
        if $src_in_subdir ; then
            strip="--strip-components 1"
        fi
        if [[ "$src_format" =~ ^tar.gz|tar.bz2|tar.xz$ ]] ; then
            tar -xf $src_filename -C "$dest_dir" $strip
        else
            ynh_die "Archive format unrecognized."
        fi
    fi

    # Apply patches
    if (( $(find $YNH_CWD/../sources/patches/ -type f -name "${src_id}-*.patch" 2> /dev/null | wc -l) > "0" )); then
        local old_dir=$(pwd)
        (cd "$dest_dir" \
            && for p in $YNH_CWD/../sources/patches/${src_id}-*.patch; do \
                patch -p1 < $p; done) \
            || ynh_die "Unable to apply patches"
        cd $old_dir
    fi

    # Add supplementary files
    if test -e "$YNH_CWD/../sources/extra_files/${src_id}"; then
        cp -a $YNH_CWD/../sources/extra_files/$src_id/. "$dest_dir"
    fi
}