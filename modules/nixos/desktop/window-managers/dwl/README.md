## DWL

### Debugging

Go to you dwl repository, build dwl, and run

```sh
$ gdb --args ./dwl -d
$ gdb > run > /home/${userName}/.cache/dwllogs 2> /home/${userName}/.cache/dwlstderrlogs
```

> **NOTE:** You might want to run it inside another compositor. If dwl segfaults, it would freeze everything, leaving you with the only option of restarting your computer.

If dwl segfaults, then you can run in the gdb console

```sh
# show backtrace
$ bt
# show source code where error occurred
$ frame 0
$ list
```

