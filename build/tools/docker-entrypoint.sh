#!/bin/bash

  #############################################
  ## filename: docker-entrypoing.sh          ##
  ## path:     ~/src/deploy/localhost/docker/build/tools             ##
  ## date:     10/14/2015                    ##
  ## purpose:  final container setup script  ##
  ## repo:     https://github.com/DevOpsEtc ##
  #############################################

# vim: set fdm=marker:                      # treat triple braces as folds

# set -e

# variables # {{{
D_BASE=/var/www/waf.dev/public
D_MAKE=/etc/drush/waf.make.yml
D_DEFAULT=$D_BASE/sites/default
D_SERVICES=$D_DEFAULT/default.services.yml
D_SETTINGS=$D_DEFAULT/default.settings.php
# }}}
main() { # {{{
  # don't do if drupal base path exists
  if [ ! -d $D_BASE ]; then

    # check if drush make file exists
    if [ -f "$D_MAKE" ]; then
      # download drush & any contrib modules
      # drush make --no-core $D_MAKE $D_BASE
      drush make -v $D_MAKE $D_BASE
    else
      echo >&2 "cannot find make file: $D_MAKE"
      echo >&2 "check mounts for /var/www"
      exit 1
    fi
    drup_files
    drup_install
  else
    drup_files
    drup_install
  fi

  tail -f /dev/null
} #}}}
drup_files() { # {{{
  # wait for these drupal files to download before continuing
  while [ ! -f "$D_SERVICES" ] && [ ! -f "$D_SETTINGS" ]; do
    sleep 2
  done

  # create settings.php if doesn't exist
  if [ ! -f $D_DEFAULT/settings.php ]; then
    cp $D_DEFAULT/{default.settings.php,settings.php}
  fi

  # create services.yml if doesn't exist
  if [ ! -f $D_DEFAULT/services.yml ]; then
    cp $D_DEFAULT/{default.services.yml,services.yml}
  fi

  # set appropriate trusted host pattern
  if [ $BUILD == "dev" ]; then
    PAT="[] = '^devopsetc\.dev$';"
  elif [ $BUILD == "test" ]; then
    PAT="[] = '^test.devopsetc\.com$';"
  elif [ $BUILD == "live" ]; then
    PAT=" = array(\n  '^devopsetc\.com$',\n  '^www\.devopsetc\.com$',\n);"
  fi

  # push trusted host pattern to new settings.php file
  sed -i "$ a\$settings['trusted_host_patterns']$PAT" $D_DEFAULT/settings.php
} # }}}
drup_install() { # {{{
  # install drupal
  drush site-install -y --db-url=mysql://root:$MYSQL_ROOT_PASSWORD@192.168.99.100:3306/$DRUP_DB --account-name=$DRUP_ADMIN --account-pass=$DRUP_ADMIN_PASS --account-mail=$DRUP_ADMIN_MAIL

  config=(
    'contact.form.feedback recipients.0 Greg@'
    'contact.form.feedback label "Website Contact"'
    'contact.settings flood.limit 10'
    'system.date country.default US'
    'system.date first_day 1'
    'system.site name DevOpsEtc.dev'
    'system.site mail Greg@'
    'system.file path.private ../private/files'
    'system.file path.temporary ../private/tmp'
    'system.maintenance message "Sorry any inconvenience, @site will be back up soon."'
    'update.settings notification.emails.0 Greg@'
    'user.settings register admin_only'
    #	'system.site page.front node'
  )

  # set drupal instance variables
  for key in "${config[@]}"; do
    ## eval $(drush -y config-set "$key")
    drush -y config-set ${key}
  done
} # }}}

main "$@"
