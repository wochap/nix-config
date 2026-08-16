## Contacts

Contacts are saved to `~/.local/share/vdirsyncer` folder

### Getting started

```sh
khard addressbooks
khard new --addressbook <addressbook> --edit
```

### Stack

- vdirsyncer:
  synchronize contacts from google (or a CardDAV server) to local vcf
  files. Google accounts reuse the shared OAuth client secrets. The shared
  timer uses the calendar frequency when calendars are active, otherwise it
  uses the contacts frequency
- khard:
  address book TUI, reads the synced local vdirs
- neomutt:
  compose-mode address completion via `query_command`
  (`khard email --parsable -- %s`), only when the mail module is enabled
- khal birthdays:
  contact birthdays shown as calendars in khal, only when the calendar
  module is enabled (per-account `khalBirthdays`, default `true`, no-op
  without the calendar stack). Uses the concrete `localCollection`
  (Google's default is `"default"`).

The shared `vdirsyncer.service` is also started whenever NetworkManager
brings a connection up. Its network condition silently skips timer runs while
offline, including contacts-only configurations.

### Setup

#### Google Contacts

1. enable the Google Contacts CardDAV API , Google People API in the same GCP project the shared
   vdirsyncer module uses (the OAuth client id/secret under
   `personal-vdirsyncer-client-id` and `personal-vdirsyncer-client-secret` sops keys). without it the
   first sync fails with a recognizable `googleapi` 403/PERMISSION_DENIED
   error.
   docs: https://vdirsyncer.pimutils.org/en/stable/config.html?highlight=google#google
1. rebuild, then run the initial OAuth flow per account (each account is a
   separate google login, so each one opens a browser asking for
   credentials):

   ```sh
   # a browser should open automatically asking for google credentials, otherwise run:
   vdirsyncer discover
   ```

   the OAuth tokens persist under `~/.local/share/vdirsyncer/` afterwards.

#### CardDAV

Accounts can point at a self-hosted CardDAV server instead of google by
setting `remote.type = "carddav"` plus `remote.url`, `remote.userName` and
`remote.passwordFile` on the account. The password file is exposed read-only
inside the hardened vdirsyncer service. Optional DAV settings include
`remote.auth`, `remote.verify`, and `remote.verifyFingerprint`; no OAuth setup
is needed.

### Notes

- new google contact lists are not picked up automatically, run
  `vdirsyncer discover` after adding a contact list on google.
- khard automatically discovers concrete collections below each account's
  local path. Native khard discovery names them from the collection itself,
  so equal names from different accounts may still receive a `-1` suffix.
- `localCollection` is only for khal birthdays and must be a concrete
  collection such as Google's `default`; vdirsyncer's `from a` / `from b`
  discovery directives are not passed to khal.
- `conflictResolution = "remote wins"`: on concurrent edits the remote
  side wins, same posture as the calendar module.
