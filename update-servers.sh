#!/bin/bash
URL="https://api.hide.me/v1/external/passepartout"
TPL="template"
SERVERS="$TPL/servers.json"

echo
echo "WARNING: Certs must be updated manually!"
echo

mkdir -p $TPL
if ! curl -L $URL >$SERVERS; then
    exit
fi
