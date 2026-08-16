## Calendar

Calendar are saved to `~/.local/share/vdirsyncer` folder

### Getting started

```sh
khal printcalendars
khal new -a <calendar> --interactive
khal new -a <calendar> tomorrow 10:00 11:00 "Personal appointment"
khal new --interactive
```

### Stack

- vdirsyncer:
  synchronize calendars from google to local ics files (every 15 minutes)
- khal:
  calendar TUI
- remind:
  notifies on events (at event start and 15 minutes before; a catch-up
  service notifies events missed while suspended or powered off)

In addition to its timer, `vdirsyncer.service` starts whenever NetworkManager
brings a connection up. Offline timer runs are skipped without failing the
unit or sending a failure notification.

### Accounts (per host)

Accounts are defined per host through `_custom.desktop.calendar.accounts`,
which maps to home-manager's `accounts.calendar.accounts` with
`vdirsyncer.enable = true` and `khal.enable = true`. hosts that define no
accounts get no calendar stack at all. example (see `hosts/glegion`):

```nix
_custom.desktop.calendar.accounts.personal = {
  name = "personal"; # defaults to the attribute name
  primary = true;
  # displayname of the main google calendar collection, becomes khal's
  # default_calendar (used by `khal new`). find it with:
  #   cat ~/.local/share/vdirsyncer/personal-calendars/*/displayname
  primaryCollection = "Holydays";
};
```

per-account options (all optional): `primaryCollection`, `localPath`,
`tokenFile`, `collections`, `conflictResolution` (default `"remote wins"`),
`metadata`, `color`, `readOnly`, `glob`, and `remote`. Google Calendar is the
default remote and uses the shared `personal-vdirsyncer-client-id` and
`personal-vdirsyncer-client-secret` SOPS secrets. module-level: `frequency`
(default `"*:0/15"`), `preAlert` (default `"+15"`, remind tdelta for the
pre-alert).

`primaryCollection` must be the displayname google gave the collection:
check the `displayname` files inside the collection subdirectories of
`localPath` on a machine that already synced.

### Setup

#### Google Calendar

1. create a project in google cloud console
   docs: https://vdirsyncer.pimutils.org/en/stable/config.html?highlight=google#google
   enable the Google CalDAV API
1. In sops secret yaml file add 2 keys: `personal-vdirsyncer-client-id` and `personal-vdirsyncer-client-secret`, you get those from [Google Console](https://vdirsyncer.pimutils.org/en/stable/config.html?highlight=google#google), then

   ```sh
   # clean current state
   systemctl --user stop vdirsyncer.timer vdirsyncer.service ics2rem.service
   rm -rf ~/.local/share/vdirsyncer
   rm -rf ~/.local/share/khal ~/.cache/khal
   rm -f ~/.config/remind/calendar-generated.rem

   # a browser should open automatically asking for google credentials, otherwise run:
   vdirsyncer discover
   ```

#### CalDAV

Accounts can use a generic CalDAV server by setting `remote.type = "caldav"`
plus `remote.url`, `remote.userName`, and `remote.passwordFile`. The password
file is exposed read-only inside the hardened vdirsyncer service. Optional
DAV settings include `remote.auth`, `remote.verify`, and
`remote.verifyFingerprint`.

#### Remind

Files:

- `~/.config/remind/remind.rem`:
  managed file read by the remind daemon, it only `INCLUDE`s the two files
  below. do not put reminders here, they would be overwritten.
- `~/.config/remind/calendar-generated.rem`:
  regenerated from the synced ics files after every vdirsyncer sync.
- `~/.config/remind/manual.rem`:
  your own hand-written reminders. create it once:

  ```sh
  touch ~/.config/remind/manual.rem
  ```

### Notes

- new google calendars are not picked up automatically, run
  `vdirsyncer discover` after adding a calendar on google.
- `conflictResolution = "remote wins"`: on concurrent edits the remote
  (google) side wins. edit events on google if you want to be safe, local
  khal edits to events that changed remotely at the same time are
  overwritten.
