#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

####################
# Migrate database #
####################

if [ -f /homeassistant/addons_config/cloudcommander ]; then
    echo "Moving database to new location /config"
    cp -rnf /homeassistant/addons_config/cloudcommander/* /config/ || true
    rm -r /homeassistant/addons_config/cloudcommander
fi

######################
# Link addon folders #
######################

# Clean symlinks
find /config -maxdepth 1 -type l -delete
if [ -d /homeassistant/addons_config ]; then
    find /homeassistant/addons_config -maxdepth 1 -type l -delete
fi

# Remove erroneous folders
if [ -d /homeassistant ]; then
    if [ -d /config/addons_config ]; then
        rm -r /config/addons_config
    fi
    if [ -d /config/addons_autoscripts ]; then
        rm -r /config/addons_autoscripts
    fi
fi

# Create symlinks with legacy folders
if [ -d /homeassistant/addons_config ]; then
    ln -s /homeassistant/addons_config /config
    find /addon_configs/ -maxdepth 1 -mindepth 1 -type d -not -name "*cloudcommander*" -exec ln -s {} /config/addons_config/ \;
fi
if [ -d /homeassistant/addons_autoscripts ]; then
    ln -s /homeassistant/addons_autoscripts /config
fi

#################
# NGINX SETTING #
#################

# declare port
# declare certfile
declare ingress_interface
declare ingress_port
# declare keyfile

CLOUDCMD_PREFIX=$(bashio::addon.ingress_entry)
export CLOUDCMD_PREFIX

declare ADDON_PROTOCOL=http
if bashio::config.true 'ssl'; then
    ADDON_PROTOCOL=https
    bashio::config.require.ssl
fi

# port=$(bashio::addon.port 80)
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
sed -i "s|%%protocol%%|${ADDON_PROTOCOL}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%port%%|${ingress_port}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%interface%%|${ingress_interface}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%subpath%%|${CLOUDCMD_PREFIX}/|g" /etc/nginx/servers/ingress.conf
mkdir -p /var/log/nginx && touch /var/log/nginx/error.log

###############
# LAUNCH APPS #
###############

if bashio::config.has_value 'CUSTOM_OPTIONS'; then
    CUSTOMOPTIONS=" $(bashio::config 'CUSTOM_OPTIONS')"
else
    CUSTOMOPTIONS=""
fi

if bashio::config.has_value 'DROPBOX_TOKEN'; then
    DROPBOX_TOKEN="--dropbox --dropbox-token $(bashio::config 'DROPBOX_TOKEN')"
else
    DROPBOX_TOKEN=""
fi

bashio::log.info "Starting..."

cd /
declare CLOUDCMD_LOG_DIR=/var/log/cloudcmd
declare CLOUDCMD_LOG_FILE=${CLOUDCMD_LOG_DIR}/cloudcmd.log
declare CLOUDCMD_BIN=""
declare -a cloudcmd_candidates=(
    /usr/src/app/bin/cloudcmd.mjs
    /usr/src/app/bin/cloudcmd.js
    /usr/src/cloudcmd/bin/cloudcmd.mjs
    /usr/src/cloudcmd/bin/cloudcmd.js
)

for candidate in "${cloudcmd_candidates[@]}"; do
    if [ -f "$candidate" ]; then
        CLOUDCMD_BIN="$candidate"
        break
    fi
done

if [ -z "$CLOUDCMD_BIN" ] && command -v cloudcmd >/dev/null 2>&1; then
    CLOUDCMD_BIN=$(command -v cloudcmd)
fi

if [ -z "$CLOUDCMD_BIN" ]; then
    bashio::log.error "Cloud Commander binary not found in expected locations or PATH."
    exit 1
fi

mkdir -p "$CLOUDCMD_LOG_DIR"
touch "$CLOUDCMD_LOG_FILE"

bashio::log.info "Using Cloud Commander binary: ${CLOUDCMD_BIN}"
bashio::log.info "Cloud Commander log file: ${CLOUDCMD_LOG_FILE}"
# shellcheck disable=SC2086
"$CLOUDCMD_BIN" $DROPBOX_TOKEN $CUSTOMOPTIONS >>"$CLOUDCMD_LOG_FILE" 2>&1 &
declare CLOUDCMD_PID=$!

bashio::log.info "Cloud Commander started with PID ${CLOUDCMD_PID}"

if ! bashio::net.wait_for 8000 localhost 900; then
    bashio::log.error "Cloud Commander did not open port 8000 within the startup timeout."
    if kill -0 "$CLOUDCMD_PID" >/dev/null 2>&1; then
        bashio::log.error "Cloud Commander process ${CLOUDCMD_PID} is still running."
    else
        bashio::log.error "Cloud Commander process ${CLOUDCMD_PID} exited before startup completed."
    fi

    if [ -s "$CLOUDCMD_LOG_FILE" ]; then
        bashio::log.error "Last 50 lines of Cloud Commander log:"
        while IFS= read -r line; do
            bashio::log.error "$line"
        done < <(tail -n 50 "$CLOUDCMD_LOG_FILE")
    else
        bashio::log.error "Cloud Commander log file is empty."
    fi
fi

bashio::log.info "Started !"
exec nginx
