## Adding music

mpd plays from `_custom.desktop.music.musicDirectory`, `~/Music` by default.
Copy music there. mpd has a single music directory, so other folders are
symlinked into it: `extraDirectories.<name> = path` links `path` as
`~/Music/<name>`. gdesktop links the Lidarr library (`<dataRoot>/media/music`,
see `modules/nixos/services/media/lidarr/README.md`) as `~/Music/library`.
New files are picked up by `auto_update`; to rescan by hand: `mpc update`.

Use mpc to add music
```
$ mpc ls | mpc add
```
