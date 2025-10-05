#!/bin-bash

set -e

SITE_KEY="/etc/tripwire/site.key"
LOCAL_KEY="/etc/tripwire/$(hostname)-local.key"
CONFIG_FILE="/etc/tripwire/tw.cfg"
POLICY_FILE="/etc/tripwire/tw.pol"
DATABASE_FILE="/var/lib/tripwire/$(hostname).twd"

echo "--- Starting Configuration Check ---"

if [ ! -f "$SITE_KEY" ]; then
  echo "Site key not found. Generating..."
  (echo "password") | twadmin --generate-keys --site-keyfile "$SITE_KEY"
else
  echo "Site key already exists. Skipping generation."
fi

if [ ! -f "$LOCAL_KEY" ]; then
  echo "Local key not found. Generating..."
  (
    echo "password"
    echo "password"
  ) | twadmin --generate-keys --local-keyfile "$LOCAL_KEY"
else
  echo "Local key already exists. Skipping generation."
fi

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Signed config file not found. Creating..."
  (echo "password") | twadmin --create-cfgfile -S "$SITE_KEY" /etc/tripwire/twcfg.txt
else
  echo "Signed config file already exists. Skipping creation."
fi

if [ ! -f "$POLICY_FILE" ]; then
  echo "Signed policy file not found. Creating..."
  (echo "password") | twadmin --create-polfile -S "$SITE_KEY" /etc/tripwire/twpol.txt
else
  echo "Signed policy file already exists. Skipping creation."
fi

if [ ! -f "$DATABASE_FILE" ]; then
  echo "Tripwire database not found. Initializing..."
  (echo "password") | tripwire --init
  echo "--- Tripwire Initialized Successfully ---"
else
  echo "Tripwire database already exists. Skipping initialization."
fi

echo "--- Configuration Check Complete ---"

echo "--- Starting Services ---"
service rsyslog start
service ssh start

echo "--- Starting Nginx ---"
nginx -g 'daemon off;'
