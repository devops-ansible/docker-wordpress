#!/usr/bin/env bash

set -ex

###
## install missing tools
###

apt-get update -q --fix-missing
apt-get -yq upgrade

# * ghostscript required to render PDF previews
# * libjpeg-dev + libmagickwand-dev required for image actions
apt-get -yq install -y --no-install-recommends \
        ghostscript \
        libjpeg-dev libmagickwand-dev \

###
## php extensions
###
docker-php-ext-install -j "$(nproc)" \
        bcmath \
        opcache

###
## WriteOut Configs
###
# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
cat <<EOF > /usr/local/etc/php/conf.d/opcache.ini
opcache.memory_consumption      = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files   = 4000
opcache.revalidate_freq         = 2
opcache.fast_shutdown           = 1
EOF

# https://www.php.net/manual/en/errorfunc.constants.php
# https://github.com/docker-library/wordpress/issues/420#issuecomment-517839670
cat <<EOF > /usr/local/etc/php/conf.d/log-errors.ini
error_reporting        = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR
display_errors         = Off
display_startup_errors = Off
log_errors             = On
error_log              = /dev/stderr
log_errors_max_len     = 1024
ignore_repeated_errors = On
ignore_repeated_source = Off
html_errors            = Off
EOF

# https://httpd.apache.org/docs/2.4/mod/mod_remoteip.html
# these IP ranges are reserved for "private" use and should thus *usually* be safe inside Docker

cat <<EOF > /etc/apache2/conf-available/remoteip.conf
RemoteIPHeader X-Forwarded-For
RemoteIPTrustedProxy 10.0.0.0/8
RemoteIPTrustedProxy 172.16.0.0/12
RemoteIPTrustedProxy 192.168.0.0/16
RemoteIPTrustedProxy 169.254.0.0/16
RemoteIPTrustedProxy 127.0.0.0/8
EOF

# https://github.com/docker-library/wordpress/issues/383#issuecomment-507886512
# (replace all instances of "%h" with "%a" in LogFormat)
find /etc/apache2 -type f -name '*.conf' -exec sed -ri 's/([[:space:]]*LogFormat[[:space:]]+"[^"]*)%h([^"]*")/\1%a\2/g' '{}' +


###
## Enable Apache modules
###
#
a2enmod rewrite \
  expires \
  remoteip \
  ldap

a2enconf remoteip


###
## Download and place external resources
###

# download and untar the wordpress source
curl -o wordpress.tar.gz -fSL "https://wordpress.org/latest.tar.gz"
# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
tar -xzf wordpress.tar.gz -C /usr/src/
rm wordpress.tar.gz
chown -R www-data:www-data /usr/src/wordpress

# entrypoint of current wordpress repo should be executed on every boot ... but no apache start =D

# current php version
phpversion=$( php <<EOF
<?php
echo "php".PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION."\n\n";
EOF
)
# fetch wp docker config template
curl -u ${WORKINGUSER}:$( id -gn ${WORKINGUSER} ) -o /usr/src/wordpress/wp-config-docker.php -fSL "https://raw.githubusercontent.com/docker-library/wordpress/master/latest/${phpversion}/apache/wp-config-docker.php"
# fetch relevant entrypoint file
curl -o /boot.d/wp.sh -fSL "https://raw.githubusercontent.com/docker-library/wordpress/master/latest/${phpversion}/apache/docker-entrypoint.sh"
apachecheck='^.*\[\[ "\$1" == apache2\* \]\].*'
# `$1` parameter is not transfered to the boot script ??? so we have to change the check to a regular variable
sed -i '/'"${apachecheck}"'/i myversion="apache2"' /boot.d/wp.sh
# replace each `$1` within the matching row and the two following rows ...
sed -i '/'"${apachecheck}"'/{N;N;s/$1/${myversion}/g}' /boot.d/wp.sh
# additionally the case check for runtime user has to be adjusted
sed -i 's/$1/${myversion}/g' /boot.d/wp.sh
# this script is not meant to start the wordpress apache service ...
sed -i '/exec "$@"/d' /boot.d/wp.sh

# activate logging for wordpress
# define( 'WP_DEBUG_LOG', true); activate logfile if set to true, the path will be wp-content/debug.log. To change the PATH to the logfile change true to the new 'path'
# define( 'WP_DEBUG_DISPLAY', false ) deactivate the return of error and warnings on the webpage itself. Needs to be set to false in production!!!
if [[ -f /boot.d/wp.sh ]]; then
cat <<EOT >>/boot.d/wp.sh
if [[ -f  wp-config.php ]]; then
    grep -qxF "define( 'WP_DEBUG_LOG', true);" wp-config.php || sed -i "/define( 'WP_DEBUG', true);/a define( 'WP_DEBUG_LOG', true);" wp-config.php
    grep -qxF "define( 'WP_DEBUG_DISPLAY', false);" wp-config.php || sed -i "/define( 'WP_DEBUG_LOG', true);/a define( 'WP_DEBUG_DISPLAY', false);" wp-config.php
fi

EOT
fi

###
## CleanUp
###

set +e

apt-get -y clean
apt-get -y autoclean
apt-get -y autoremove
rm -r /var/lib/apt/lists/*
