#!/bin/bash
set -e

# set path/file variables
P1=/etc/drush/waf.make.yml
P2=/var/www/waf.dev
P3=$P2/public/sites/default
P4=$P3/default.services.yml
P5=$P3/default.settings.php

# array of drupal config
config=(
  'contact.form.feedback recipients.0 ??@??.com'
  'contact.form.feedback label "Website Contact"'
  'contact.settings flood.limit 10'
  'system.date country.default US'
  'system.date first_day 1'
  'system.site name ??'
  'system.site mail ??@????.com'
  'system.file path.private ../private/files'
  'system.file path.temporary ../private/tmp'
  'system.maintenance message "Sorry any inconvenience, @site will be back up soon."'
  'update.settings notification.emails.0 ??@???.com'
  'user.settings register admin_only'
#	'system.site page.front node'
)

# check if volume exists
if [ ! -d "$P2" ]; then
  echo >&2 "cannot find volume: $P2"
  exit 1
fi

# check if drush make file exists
if [ -f "$P1" ]; then
  # download drush & any contrib modules
  # drush make --no-core $P1 $P2/public
  drush make $P1 $P2/public
else
  echo >&2 "cannot find drush make file: $P1"
  exit 1
fi

# do not continue until these two files are downloaded via drush make above
while [ ! -f "$P4" ] && [ ! -f "$P5" ]; do
  sleep 2
  # spin
done
# endspin

# create settings.php and services.yml files
  cp $P3/{default.services.yml,services.yml}
  cp $P3/{default.settings.php,settings.php}

# set appropriate trusted host pattern
if [ $BUILD == "dev" ]; then
  PAT="[] = '^???\.dev$';"
elif [ $BUILD == "test" ]; then
  PAT="[] = '^test.???\.com$';"
elif [ $BUILD == "live" ]; then
  PAT=" = array(\n  '^???\.com$',\n  '^www\.???\.com$',\n);"
fi

# push trusted host pattern to new settings.php file
sed -i "$ a\$settings['trusted_host_patterns']$PAT" $P3/settings.php

# install drupal
# use env variables for credentials
# drush site-install -y --db-url=mysql://root:$MYSQL_ROOT_PASSWORD@192.168.99.100:3306/$DRUP_DB --account-name=$DRUP_ADMIN --account-pass=$DRUP_ADMIN_PASS --account-mail=$DRUP_ADMIN_MAIL

# while [ drush version &>/dev/null ]; do
  # sleep 2
# done
# set drupal instance variables
# for key in "${config[@]}"; do
  # eval $(drush -y config-set "$key")
  # drush -y config-set ${key}
# done

# drush
tail -f /dev/null
