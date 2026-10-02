# Nix: package a shell script

`src/greet.sh` is a finished script (do not edit it). It needs `jq` on `PATH` and reads its
version from the `GREET_VERSION` environment variable:

```console
$ greet Ann            # Hello, Ann!
$ greet --json Ann     # {"greeting":"Hello, Ann!"}
$ greet --version      # greet 1.2.0
```

Write two files.

## `package.nix`

A function for `pkgs.callPackage ./package.nix { }` that returns one derivation:

- `pname = "greet"`, `version = "1.2.0"` (so `name` is `greet-1.2.0`).
- The source of the build is the `src/` directory only: `pkg.src` must be a directory whose
  only entry is `greet.sh`. Changes to other files in the project must not change the package.
- Installs the script as `$out/bin/greet` (executable). Nothing else in `$out/bin`.
- `$out/bin/greet` must work with an empty environment (`env -i $out/bin/greet --json Ann`):
  `jq` and `GREET_VERSION` are provided by the package itself.
- `greet --version` prints `greet <version>`, where `<version>` is the derivation's `version`
  attribute. This must stay true for `pkg.overrideAttrs { version = "9.9.9"; }`
  (that package prints `greet 9.9.9`).
- `meta.mainProgram = "greet"`, `meta.license` is `lib.licenses.mit`,
  `meta.description` is a non-empty string.
- `jq` must not appear in `propagatedBuildInputs` or `propagatedNativeBuildInputs`.

## `default.nix`

A function `{ pkgs }:` returning an attrset with:

- `greet`: `pkgs.callPackage ./package.nix { }`.
- `greet-dev`: `greet` with version `"1.2.0-dev"` (`greet-dev --version` prints `greet 1.2.0-dev`,
  its `name` is `greet-1.2.0-dev`).
- `run-greet`: a derivation that, when built, produces a single executable file `$out/bin/hello-all`
  which runs `greet` from the `greet` package with each of its arguments in order, one line per
  argument (`hello-all Ann Bo` prints `Hello, Ann!` then `Hello, Bo!`). No arguments prints nothing.
  It must work with an empty environment too.

## Checks

`bash check.sh` runs `nixfmt --check`, `statix check`, `deadnix --fail`, then `tests/run.sh`,
which evaluates and builds the attributes above with nixpkgs from the flake registry.
