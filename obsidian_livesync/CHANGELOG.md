## 3.5.1-5 (2026-04-12)
- Stop overwriting existing private vault user passwords from `VAULT_USERS` on restart so users can rotate their own CouchDB password later

## 3.5.1-4 (2026-04-12)
- Add `VAULT_USERS` support to provision multiple private LiveSync vault users in one addon instance
- Apply per-database CouchDB security policies so separate users can keep separate private vaults
- Warn on startup when the default admin password is still in use

## 3.5.1-3 (2026-04-11)
- Pin the Docker base image directly to CouchDB 3.5.1 so Supervisor source builds do not replace it with the Home Assistant base image

## 3.5.1-2 (2026-04-11)
- Start CouchDB without depending on a /docker-entrypoint.sh symlink and use numeric UID/GID 5984 for data ownership
- Write admin and optional secret config explicitly during addon init

## 3.5.1-1 (2026-04-11)
- Initial Obsidian LiveSync addon
- Package CouchDB 3.5.1 with LiveSync-compatible auth and CORS defaults
- Auto-create CouchDB system databases and an optional default vault database
