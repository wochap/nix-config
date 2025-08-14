## Calendar

Calendar are saved to `~/.local/share/vdirsyncer` folder

### Stack

- remind:
  notifies on events
- vdirsyncer:
  synchronize calendars and contacts
- khal:
  calendar TUI

### Setup

#### Remind

```
touch ~/.config/remind/remind.rem
```

#### Google Calendar

1. create a project in google cloud console
   docs: https://vdirsyncer.pimutils.org/en/stable/config.html?highlight=google#google
1. In `<NIX_CONFIG_PATH>/secrets/vdirsyncer` add 2 files: `vda_client_id` and `vda_client_secret`, you get those from [Google Console](https://vdirsyncer.pimutils.org/en/stable/config.html?highlight=google#google), then

   ```
   # remove any token file in
   $ cd ~/.local/share/vdirsyncer

   # restart vdirsyncer service
   # a browser should open automatically asking for google credentials, otherwise run:
   # generate new tokens with the following command
   $ vdirsyncer discover
   ```
