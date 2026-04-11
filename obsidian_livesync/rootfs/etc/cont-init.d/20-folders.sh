#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

mkdir -p /config/data
chown -R couchdb:couchdb /config/data || true
chmod 700 /config/data || true

if [ -e /opt/couchdb/data ] && [ ! -L /opt/couchdb/data ]; then
    rm -rf /opt/couchdb/data
fi

if [ ! -e /opt/couchdb/data ]; then
    ln -s /config/data /opt/couchdb/data
fi
