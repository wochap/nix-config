## Contacts

Contacts are saved to `~/.local/share/vdirsyncer` folder

### Stack

- vdirsyncer:
  synchronize contacts from google (or a CardDAV server) to local vcf
  files. reuses the calendar module's OAuth client secrets and shares the
  calendar module's vdirsyncer timer when the calendar stack is active
  (otherwise this module owns the timer with its own `frequency`)
- khard:
  address book TUI, reads the synced local vdirs
- neomutt:
  compose-mode address completion via `query_command`
  (`khard email --parsable -- %s`), only when the mail module is enabled
- khal birthdays:
  contact birthdays shown as calendars in khal, only when the calendar
  module is enabled (per-account `khalBirthdays`, default `true`, no-op
  without the calendar stack) and the account's `collections` is set
  (see notes)

### Setup

#### Google Contacts

1. enable the Google Contacts CardDAV API , Google People API in the same GCP project the calendar
   module already uses (the OAuth client id/secret under
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
`remote.passwordCommand` on the account. no OAuth setup needed.

### Notes

- new google contact lists are not picked up automatically, run
  `vdirsyncer discover` after adding a contact list on google.
- khard and khal birthdays read the discovered collections (subdirectories
  of the account's `localPath`), check them after the first sync.
- khal birthdays need the account's `collections` set to the discovered
  collection names (mirrors how the calendar module's `primaryCollection`
  is discovered):
  `ls ~/.local/share/vdirsyncer/<name>-contacts/` after the first sync.
  until then birthdays stay disabled (a nixos warning says so).
- `conflictResolution = "remote wins"`: on concurrent edits the remote
  side wins, same posture as the calendar module.
