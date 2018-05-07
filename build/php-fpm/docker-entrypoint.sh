#!/bin/bash
set -e

# configure ssmtp mta
sed -i \
  -e "s/root=.*/root=$SMTP_ROOT/" \
  -e "s/#rewriteDomain=.*/rewriteDomain=$SMTP_REWRITE_DOMAIN/" \
  -e "s/mailhub=.*/mailhub=$SMTP_MAILHUB/" \
  -e "$ a\AuthUser=$SMTP_NAME" \
  -e "$ a\AuthPass=$SMTP_PASS" \
  /etc/ssmtp/ssmtp.conf
