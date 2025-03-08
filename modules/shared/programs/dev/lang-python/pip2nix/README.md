# Python

> Docs: ![The Best Way To Use Python On NixOS](https://www.youtube.com/watch?v=6fftiTJ2vuQ&t=276s)

To add a package from https://pypi.org/, update `requirements.txt`, for example: `bt-dualboot==1.0.1`

```sh
# the following will generate `python-packages.nix`
$ nix run github:nix-community/pip2nix -- generate ./requirements.txt
$ nix run github:nix-community/pip2nix -- generate <package_name>
# copy `python-packages.nix` contents to local `python-packages.nix`
# NOTE: sometimes you will need to tune manually `python-packages.nix`
```
