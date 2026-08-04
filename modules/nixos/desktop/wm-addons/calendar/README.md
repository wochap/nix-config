## Calendar

Calendar are saved to `~/.local/share/vdirsyncer` folder

### Stack

- remind:
  notifies on events (at event start and 15 minutes before; a catch-up
  service notifies events missed while suspended or powered off)
- vdirsyncer:
  synchronize calendars and contacts
- khal:
  calendar TUI

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

Timed events notify at event start and 15 minutes before
(`ics2rem --posttime "+15"`, see `man remind` for the `tdelta` syntax to
change it). all-day events notify at midnight of the event day.

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

- new google calendars are picked up automatically during sync
  (`implicit = "create"`), `vdirsyncer discover` is only needed for the
  initial setup, re-authentication or troubleshooting.
- `conflict_resolution = "b wins"`: on concurrent edits the remote (google)
  side wins. edit events on google if you want to be safe, local khal edits
  to events that changed remotely at the same time are overwritten.
