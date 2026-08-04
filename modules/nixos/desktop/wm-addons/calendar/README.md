## Calendar

Calendar are saved to `~/.local/share/vdirsyncer` folder

### Stack

- remind:
  notifies on events (at event start and 15 minutes before; a catch-up
  service notifies events missed while suspended or powered off)
- vdirsyncer:
  synchronize calendars (`programs.vdirsyncer` + `services.vdirsyncer`
  home-manager modules, every 15 minutes, `Persistent` timer)
- khal:
  calendar TUI (`programs.khal` home-manager module)

### Accounts (per host)

Accounts are defined per host through `_custom.desktop.calendar.accounts`,
which maps to home-manager's `accounts.calendar.accounts` with
`vdirsyncer.enable = true` and `khal.enable = true`. hosts that define no
accounts get no calendar stack at all. example (see `hosts/glegion`):

```nix
_custom.desktop.calendar.accounts.personal = {
  name = "personal"; # defaults to the attribute name
  primary = true;
  # once set, becomes khal's default_calendar (used by `khal new`)
  primaryCollection = "Gean Marroquin"; # displayname of the main collection
};
_custom.desktop.calendar.accounts.se = {
  name = "se";
};
```

per-account options worth knowing (all optional): `primaryCollection`,
`localPath`, `tokenFile`,
`clientIdCommand`/`clientSecretCommand` (default to the shared
`~/.config/secrets/vdirsyncer/vda_client_id|secret`), `collections`,
`conflictResolution` (default `"remote wins"`), `metadata`, `color`,
`readOnly`, `glob`. module-level: `frequency` (default `"*:0/15"`),
`preAlert` (default `"+15"`, remind tdelta for the pre-alert).

home-manager generates:

- vdirsyncer pair `calendar_<name>` with storages
  `calendar_<name>_local`/`calendar_<name>_remote`
  (note: `a` is the remote side, so `"remote wins"` maps to
  `conflict_resolution = "a wins"`).
- khal calendar `[[<name>]]` (`type = discover` over `localPath`). note
  that khal expands discover calendars into one calendar per collection,
  named after the collection's displayname (synced from google), so
  `default_calendar` cannot be the account name; set `primaryCollection`
  to the displayname of your main calendar (see the `displayname` files
  inside the collection subdirectories of `localPath`).
- on the first activation after this migration, `vdirsyncer.service`
  renames the old `<name>_google_calendar` status entries to
  `calendar_<name>`, which preserves the per-item sync state. because the
  discovery cache key changed with the new pair layout, run
  `vdirsyncer discover` once after activating (items are not re-downloaded).

### Setup

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

Timed events notify at event start and `preAlert` (15 minutes) before
(`ics2rem --posttime`, see `man remind` for the `tdelta` syntax to change
it). all-day events notify at midnight of the event day.

`remind-catchup.service` (+ timer, every 2 minutes) notifies reminders that
triggered while the machine was suspended or powered off (up to 7 days
back). on the very first run it only initializes its state file
(`~/.local/state/remind/last-check`) without notifying.

#### Google Calendar

1. create a project in google cloud console
   docs: https://vdirsyncer.pimutils.org/en/stable/config.html?highlight=google#google
1. In `<NIX_CONFIG_PATH>/secrets/vdirsyncer` add 2 files: `vda_client_id` and `vda_client_secret`, you get those from [Google Console](https://vdirsyncer.pimutils.org/en/stable/config.html?highlight=google#google), then

   ```
   # remove any token file in
   $ cd ~/.local/share/vdirsyncer/*_token_file

   # restart vdirsyncer service
   # a browser should open automatically asking for google credentials, otherwise run:
   # generate new tokens with the following command
   $ vdirsyncer discover
   ```

### Notes

- the home-manager vdirsyncer module does not support `implicit = "create"`,
  so new google calendars are NOT picked up automatically anymore: run
  `vdirsyncer discover` after adding a calendar on google (also needed for
  the initial setup, the one-time migration above, or re-authentication).
- `conflictResolution = "remote wins"`: on concurrent edits the remote
  (google) side wins. edit events on google if you want to be safe, local
  khal edits to events that changed remotely at the same time are
  overwritten.
- the khal theme variants `~/.config/khal/config-light|config-dark` are
  gone, the theme is now picked at evaluation time from
  `_custom.globals.preferDark`.
