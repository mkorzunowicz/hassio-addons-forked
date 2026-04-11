#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

COUCHDB_UID=5984
COUCHDB_GID=5984
DOCKER_INI=/opt/couchdb/etc/local.d/docker.ini

mkdir -p /config/data
chown -R ${COUCHDB_UID}:${COUCHDB_GID} /config/data || true
chmod 700 /config/data || true

mkdir -p /opt/couchdb/etc/local.d

cat > "$DOCKER_INI" <<EOF
[admins]
$(bashio::config 'COUCHDB_USER') = $(bashio::config 'COUCHDB_PASSWORD')
EOF

if bashio::config.has_value 'COUCHDB_SECRET'; then
    cat >> "$DOCKER_INI" <<EOF

[chttpd_auth]
secret = $(bashio::config 'COUCHDB_SECRET')
EOF
fi

chown ${COUCHDB_UID}:${COUCHDB_GID} "$DOCKER_INI" || true
chmod 640 "$DOCKER_INI" || true

if [ -e /opt/couchdb/data ] && [ ! -L /opt/couchdb/data ]; then
    rm -rf /opt/couchdb/data
fi

if [ ! -e /opt/couchdb/data ]; then
    ln -s /config/data /opt/couchdb/data
fi
