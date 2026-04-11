# Home Assistant add-on: Obsidian LiveSync

This add-on packages a CouchDB server configured for the Self-hosted LiveSync Obsidian plugin.

## What this add-on is

The upstream Obsidian LiveSync project does not ship a separate dedicated server binary for the common self-hosted setup. Its recommended self-hosted backend is CouchDB with specific auth and CORS settings. This add-on provides that CouchDB backend in a Home Assistant-friendly package.

## Features

- CouchDB 3.5.1
- LiveSync-compatible CORS defaults for Obsidian clients
- Required system databases created automatically
- Optional default vault database created on first boot
- Easy exposure on port `5984` for use with your reverse proxy
- Fauxton admin UI available at `/_utils/`

## Configuration

| Option | Default | Description |
| --- | --- | --- |
| `COUCHDB_USER` | `obsidian` | Admin username used by LiveSync |
| `COUCHDB_PASSWORD` | `change_me` | Admin password. Change this before exposing the addon |
| `COUCHDB_SECRET` | unset | Optional CouchDB shared secret |
| `DEFAULT_DATABASE` | `obsidian-livesync` | Database created automatically on first boot |
| `PUBLIC_URL` | unset | Optional public URL used only for startup hints in logs |

## Reverse proxy

A dedicated subdomain is the simplest setup, for example `https://notes-db.example.com`.

If you publish CouchDB through a path-based reverse proxy instead of a subdomain, make sure the proxy rewrites requests correctly and preserves authorization headers. The upstream LiveSync docs recommend avoiding root-path mounting tricks when possible.

## Obsidian LiveSync settings

After the addon starts, configure the plugin with:

- URI: your public CouchDB URL, for example `https://notes-db.example.com`
- Username: the value of `COUCHDB_USER`
- Password: the value of `COUCHDB_PASSWORD`
- Database name: the value of `DEFAULT_DATABASE`, or any database name you prefer

You can also verify the server in Fauxton at:

- `http://homeassistant.local:5984/_utils/`
- or your reverse-proxied public URL plus `/_utils/`

## Notes

- Mobile Obsidian clients generally need a valid HTTPS certificate.
- This addon exposes plain CouchDB, not the Obsidian plugin itself.
- If you only want internal access from other addons, clear port `5984` in Home Assistant network settings.

## Source

- LiveSync plugin: https://github.com/vrtmrz/obsidian-livesync
- Reference server setup: https://github.com/vrtmrz/self-hosted-livesync-server
