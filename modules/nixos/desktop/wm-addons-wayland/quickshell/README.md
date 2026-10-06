## Fprintd

```
fprintd-list $USER        # should now list a device, not "No devices available"
fprintd-enroll
fprintd-verify
systemctl --user restart shell-lock && shell-lock --lock
```
