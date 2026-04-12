#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

curl -fsS \
	-u "$(bashio::config 'COUCHDB_USER'):$(bashio::config 'COUCHDB_PASSWORD')" \
	http://127.0.0.1:5984/_up >/dev/null
