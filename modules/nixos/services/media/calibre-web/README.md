# Calibre-Web Automated

Ebook library and web reader. Files dropped in `/data/media/books/ingest` are converted, added to the Calibre library in `/data/media/books/library`, and removed from ingest. In the container, these are `/cwa-book-ingest` and `/calibre-library`.

LinuxServer-based (s6-overlay) image: starts as root with a minimal capability set, then drops to `PUID`/`PGID`.

## URLs

| URL | Reachable from |
|---|---|
| `https://calibre-web.wochap.local` | This host |
| `http://127.0.1.1:21021` | This host |
| `https://calibre-web.<web-gate.domain>`, e.g. `https://calibre-web.gdesktop.geanmar.com` | LAN devices, when `web-proxies.calibre-web.expose.enable` |
| `http://media-calibre-web:8083` | Other containers |

## Depends on / used by

- Depends on: LazyLibrarian fills the ingest folder. No network dependency.
- Used by: readers, in a browser or an OPDS app.

## Setup

### A) Without declarative

1. Open `https://calibre-web.wochap.local` on the host. Sign in with the default `admin` / `admin123`, then change the password under Admin › Edit user.
2. On the database prompt, set the library location to `/calibre-library`. The library starts empty.
3. Optional: under Admin › Users, add one user per reader.

[LazyLibrarian](../lazylibrarian/README.md#setup) drops ebooks into `/cwa-book-ingest`, and CWA imports them.

### B) With declarative

Automatic: nothing. Do steps 1–3. Change the default password before you expose the service on the LAN.

## Mobile/TV clients

Any OPDS reader (KOReader, Moon+ Reader, ...): catalog URL `https://calibre-web.<web-gate.domain>/opds`, with the reader's Calibre-Web login. Or use the web reader in a mobile browser.

## Troubleshooting

- Logs: `journalctl -u podman-media-calibre-web`.
- Books stay in ingest: check the logs for conversion errors. The ingest folder must be writable by the `media` group.

## Reset / backup

State: `/var/lib/media-server/calibre-web` (users, settings). The library itself is `dataRoot/media/books/library`: back up both.

To reset: `sudo systemctl stop podman-media-calibre-web`, delete the state directory, `sudo systemctl start podman-media-calibre-web`. Redo steps 1–3; the library stays.

## Upgrade

Option `images.calibreWeb`, image `docker.io/crocodilestick/calibre-web-automated`. [Release notes](https://github.com/crocodilestick/Calibre-Web-Automated/releases). Procedure: [Upgrading images](../README.md#upgrading-images).
