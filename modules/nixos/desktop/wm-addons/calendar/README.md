## Calendar

Calendar are saved to `~/.local/share/vdirsyncer` folder

### Stack

- vdirsyncer:
  synchronize calendars from google to local ics files (every 15 minutes)
- khal:
  calendar TUI
- remind:
  notifies on events (at event start and 15 minutes before; a catch-up
  service notifies events missed while suspended or powered off)

### Accounts (per host)

Accounts are defined per host through `_custom.desktop.calendar.accounts`,
which maps to home-manager's `accounts.calendar.accounts` with
`vdirsyncer.enable = true` and `khal.enable = true`. hosts that define no
accounts get no calendar stack at all. example (see `hosts/glegion`):

```nix
_custom.desktop.calendar.accounts.personal = {
  name = "personal"; # defaults to the attribute name
  primary = true;
  # displayname of the main google calendar collection, once set it
  # becomes khal's default_calendar (used by `khal new`)
  # $ cat ~/.local/share/vdirsyncer/personal-calendars/*/displayname
  primaryCollection = "Holydays";
};
```

per-account options (all optional): `primaryCollection`, `localPath`,
`tokenFile`, `clientIdCommand`/`clientSecretCommand` (default to the shared
`~/.config/secrets/vdirsyncer/vda_client_id|secret`), `collections`,
`conflictResolution` (default `"remote wins"`), `metadata`, `color`,
`readOnly`, `glob`. module-level: `frequency` (default `"*:0/15"`),
`preAlert` (default `"+15"`, remind tdelta for the pre-alert).

`primaryCollection` must be the displayname google gave the collection:
check the `displayname` files inside the collection subdirectories of
`localPath` on a machine that already synced.

### Setup

#### Google Calendar

1. create a project in google cloud console
   docs: https://vdirsyncer.pimutils.org/en/stable/config.html?highlight=google#google
1. In `<NIX_CONFIG_PATH>/secrets/vdirsyncer` add 2 files: `vda_client_id` and `vda_client_secret`, you get those from [Google Console](https://vdirsyncer.pimutils.org/en/stable/config.html?highlight=google#google), then

   ```
   # a browser should open automatically asking for google credentials, otherwise run:
   $ vdirsyncer discover
   ```

#### Remind

Files:

- `~/.config/remind/remind.rem`:
  managed file read by the remind daemon, it only `INCLUDE`s the two files
  below. do not put reminders here, they would be overwritten.
- `~/.config/remind/calendar-generated.rem`:
  regenerated from the synced ics files after every vdirsyncer sync.
- `~/.config/remind/manual.rem`:
  your own hand-written reminders. create it once:

  ```
  touch ~/.config/remind/manual.rem
  ```

### Notes

- new google calendars are not picked up automatically, run
  `vdirsyncer discover` after adding a calendar on google.
- `conflictResolution = "remote wins"`: on concurrent edits the remote
  (google) side wins. edit events on google if you want to be safe, local
  khal edits to events that changed remotely at the same time are
  overwritten.
