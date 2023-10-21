# Python

To add a package from https://pypi.org/

```
$ git clone https://github.com/nix-community/pip2nix --depth 1
$ cd pip2nix
$ nix-shell release.nix -A pip2nix.python39
```

Then update `requirements.txt`, for example: `animdl==1.7.22`

```
# the following will generate `python-packages.nix`
$ pip2nix generate -r requirements.txt
# copy `python-packages.nix` contents to local `python-packages.nix`
# NOTE: sometimes you will need to tune manually `python-packages.nix`
```

