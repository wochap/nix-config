## Calendar

* vdirsyncer
  synchronize calendars and contacts
  it requires to create a project in google cloud console
  docs: https://vdirsyncer.pimutils.org/en/stable/config.html?highlight=google#google
* khal
  calendar TUI

### Setup

In `<NIX_CONFIG_PATH>/secrets/vdirsyncer` add 2 files: `vda_client_id` and `vda_client_secret`, you get those from [Google Console](https://vdirsyncer.pimutils.org/en/stable/config.html?highlight=google#google), then

```
# remove any token file in
$ cd ~/.local/share/vdirsyncer

# generate new tokens
$ vdirsyncer discover
```
