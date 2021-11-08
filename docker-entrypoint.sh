#!/bin/bash

set -e

DRUPAL_PROJECT_NAME=${DRUPAL_PROJECT_NAME:-"openculturas/openculturas-project"}
DRUPAL_PROJECT_VERSION=${DRUPAL_PROJECT_VERSION:-"dev-main"}

# Project directories.
APACHE_DOCUMENT_ROOT=${APACHE_DOCUMENT_ROOT:-"/var/www/html/web"}
DRUPAL_PROJECT_ROOT=${DRUPAL_PROJECT_ROOT:-"/var/www/html"}

# Allow users to override the docroot by setting an environment variable.
if [ "$APACHE_DOCUMENT_ROOT" != "/var/www/html" ]; then
  sed -ri -e "s|DocumentRoot .*|DocumentRoot $APACHE_DOCUMENT_ROOT|g" /etc/apache2/sites-enabled/*.conf
  sed -ri -e "s|DocumentRoot .*|DocumentRoot $APACHE_DOCUMENT_ROOT|g" /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
fi

# Download Drupal to $APACHE_DOCUMENT_ROOT if it's not present.
if [ ! -f $APACHE_DOCUMENT_ROOT/index.php ] && [ $DRUPAL_DOWNLOAD_IF_NOT_PRESENT = true ]; then
  echo "Removing any existing files inside $DRUPAL_PROJECT_ROOT..."
  find $DRUPAL_PROJECT_ROOT -type f -maxdepth 1 -delete || true

  cd $DRUPAL_PROJECT_ROOT
  composer --version
  composer create-project --no-interaction --remove-vcs $DRUPAL_PROJECT_NAME:$DRUPAL_PROJECT_VERSION .

  echo "Configuring settings.php with environment variables..."
  cp $APACHE_DOCUMENT_ROOT/sites/default/default.settings.php $APACHE_DOCUMENT_ROOT/sites/default/settings.php
  cat <<EOF >> $APACHE_DOCUMENT_ROOT/sites/default/settings.php
\$databases['default']['default'] = array (
  'database' => '$DRUPAL_DATABASE_NAME',
  'username' => '$DRUPAL_DATABASE_USERNAME',
  'password' => '$DRUPAL_DATABASE_PASSWORD',
  'prefix' => '$DRUPAL_DATABASE_PREFIX',
  'host' => '$DRUPAL_DATABASE_HOST',
  'port' => '$DRUPAL_DATABASE_PORT',
  'namespace' => 'Drupal\\\\Core\\\\Database\\\\Driver\\\\mysql',
  'driver' => 'mysql',
);
\$settings["config_sync_directory"] = '../config/sync';
\$settings['hash_salt'] = '$DRUPAL_HASH_SALT';
EOF

  echo "Correcting permissions on /var/www..."
  chown -R www-data:www-data /var/www

  echo "Drupal codebase ready! Now!"
fi

exec "$@"
