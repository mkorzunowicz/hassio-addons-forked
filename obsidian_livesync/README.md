# Home Assistant add-on: Obsidian LiveSync

This add-on packages a CouchDB server configured for the Self-hosted LiveSync Obsidian plugin.

## What this add-on is

The upstream Obsidian LiveSync project does not ship a separate dedicated server binary for the common self-hosted setup. Its recommended self-hosted backend is CouchDB with specific auth and CORS settings. This add-on provides that CouchDB backend in a Home Assistant-friendly package.

## Features

- CouchDB 3.5.1
- LiveSync-compatible CORS defaults for Obsidian clients
- Required system databases created automatically
- Optional default vault database created on first boot
- Optional private multi-vault provisioning with per-user CouchDB access
- Easy exposure on port `5984` for use with your reverse proxy
- Fauxton admin UI available at `/_utils/`

## Configuration

| Option | Default | Description |
| --- | --- | --- |
| `COUCHDB_USER` | `obsidian` | Admin username used by LiveSync |
| `COUCHDB_PASSWORD` | `change_me` | Internal admin password. Change this before exposing the addon |
| `COUCHDB_SECRET` | unset | Optional CouchDB shared secret |
| `DEFAULT_DATABASE` | `obsidian-livesync` | Database created automatically on first boot |
| `VAULT_USERS` | unset | JSON array of private vault users to provision with per-database ACLs |
| `PUBLIC_URL` | unset | Optional public URL used only for startup hints in logs |

### Private vaults for multiple users

If you want separate private vaults in one addon instance, set `VAULT_USERS` to a JSON array like this:

```json
[
	{
		"username": "alice",
		"password": "alice-long-random-password",
		"database": "alice-vault"
	},
	{
		"username": "bob",
		"password": "bob-long-random-password",
		"database": "bob-vault"
	}
]
```

On startup the addon will:

- create each CouchDB user in `_users`
- create each listed database
- apply a `_security` policy so only the matching listed users can access that database

If a listed CouchDB user already exists, the addon keeps that existing user document and does not overwrite the password on restart. This lets the user rotate their password later in CouchDB or Fauxton without Home Assistant changing it back.

If multiple entries point to the same database, those users share one vault.

When `VAULT_USERS` is set, the addon admin credentials stay for maintenance and bootstrap, while each Obsidian client should use its own vault user credentials instead of the admin account.

This does not hide secrets from a Home Assistant administrator. A Home Assistant admin effectively controls the addon host and can still inspect addon configuration, logs, or CouchDB directly. What this change does provide is user-managed password rotation after first bootstrap.

## Reverse proxy

A dedicated subdomain is the simplest setup, for example `https://notes-db.example.com`.

If you publish CouchDB through a path-based reverse proxy instead of a subdomain, make sure the proxy rewrites requests correctly and preserves authorization headers. The upstream LiveSync docs recommend avoiding root-path mounting tricks when possible.

## Obsidian LiveSync settings

After the addon starts, configure the plugin with:

- URI: your public CouchDB URL, for example `https://notes-db.example.com`
- Username: the private vault username from `VAULT_USERS`, or `COUCHDB_USER` in single-user mode
- Password: the matching password for that vault user, or `COUCHDB_PASSWORD` in single-user mode
- Database name: the vault database assigned to that user, or `DEFAULT_DATABASE` in single-user mode

You can also verify the server in Fauxton at:

- `http://homeassistant.local:5984/_utils/`
- or your reverse-proxied public URL plus `/_utils/`

## Notes

- Mobile Obsidian clients generally need a valid HTTPS certificate.
- This addon exposes plain CouchDB, not the Obsidian plugin itself.
- If you only want internal access from other addons, clear port `5984` in Home Assistant network settings.
- Prefer a reverse proxy with HTTPS rather than exposing port `5984` directly.
- Enable end-to-end encryption in the LiveSync plugin, and keep the Setup URI passphrase separate from the vault encryption passphrase.

## Source

- LiveSync plugin: https://github.com/vrtmrz/obsidian-livesync
- Reference server setup: https://github.com/vrtmrz/self-hosted-livesync-server
