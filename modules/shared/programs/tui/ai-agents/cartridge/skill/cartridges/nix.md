# nix cartridge — target: Nix 2.x (flakes), nixpkgs unstable / 26.05

## Rules (DON'T → DO)
- DON'T use `nix-env -i` → DO add packages declaratively, or `nix profile add` / `nix shell nixpkgs#pkg`
- DON'T use `nix-build`, `nix-shell` in flake repos → DO use `nix build`, `nix develop`, `nix shell`
- DON'T use `sha256 = "..."` with base32 → DO use `hash = "sha256-...="` (SRI)
- DON'T guess a hash → DO set `hash = lib.fakeHash;`, build, copy the "got:" hash from the error
- DON'T write `with pkgs; [ ... ]` at file top level → DO use it only on a list: `with pkgs; [ git jq ]`
- DON'T use `rec { }` for big attrsets → DO use `let ... in { }` (rec causes infinite recursion and shadowing)
- DON'T use `pkgs.system` → DO use `pkgs.stdenv.hostPlatform.system` (old name is deprecated)
- DON'T use `nixfmt-rfc-style` → DO use `pkgs.nixfmt` (RFC style is now the default nixfmt)
- DON'T use `pkgs.nerdfonts.override { fonts = [...]; }` → DO use `pkgs.nerd-fonts.jetbrains-mono`
- DON'T use `nix flake lock --update-input x` → DO use `nix flake update x`
- DON'T put `${pkgs.foo}/bin/foo` by hand → DO use `lib.getExe pkgs.foo` or `lib.getExe' pkgs.foo "bin-name"`
- DON'T use `if cond then x else null` inside lists → DO use `lib.optionals cond [ x ]`
- DON'T use `import <nixpkgs> {}` in flakes → DO use `inputs.nixpkgs.legacyPackages.${system}` or the module `pkgs` arg
- DON'T use `builtins.fetchTarball` without a hash in flakes → DO add a flake input instead

## Gotchas
- Evaluation is lazy: an error inside an unused attr never shows until something forces it.
- Function application binds tighter than everything: `f a ++ b` is `(f a) ++ b`; use parens.
- List elements are split by spaces: `[ f x ]` is two elements; write `[ (f x) ]`.
- `?` and `or` inside a list also need parens: `[ (a ? b) ]`.
- `a.b or c` defaults only when the attr is missing, not when it is null.
- `//` is shallow merge; right side wins; nested attrsets are replaced, not merged. Use `lib.recursiveUpdate`.
- `with` never shadows `let` bindings or function args; inner `let` always wins over `with`.
- `rec { a = 1; b = a; }` works, but `rec { x = x; }` is infinite recursion.
- `inherit (pkgs) git;` means `git = pkgs.git;`.
- Indented strings `''...''`: escape `${` as `''${`, escape `''` as `'''`. `$` alone needs no escape.
- In `"..."` strings escape `${` as `\${`.
- In `writeShellScript*` text, bash `${VAR}` must be written `''${VAR}` (else Nix interpolates it).
- Paths (`./foo`) are copied to the store when interpolated: `"${./foo}"` becomes `/nix/store/...-foo`.
- `toString ./foo` gives the local path string, no store copy.
- Flakes only see git-tracked files: `git add` new files or you get "path does not exist".
- `builtins.readFile` of a store path from a build output is import-from-derivation (slow/blocked).
- Attr names with dashes or dots need quotes: `"foo.bar" = 1;` vs `foo.bar = 1;` (nested).
- `builtins.trace` and `lib.traceVal` print during eval; useful for debugging.
- `callPackage ./pkg.nix { }` fills function args from `pkgs`; the `{ }` overrides some.
- mkDerivation: overriding `buildPhase` disables the default; call `runHook preBuild` / `runHook postBuild` yourself.
- `nativeBuildInputs` = tools run at build time (cmake, pkg-config); `buildInputs` = libs linked.
- `src = ./.;` copies the whole dir incl. `result` links; use `lib.fileset.toSource`.

## Correct API names
- `lib.optional` → returns `[x]` or `[]` for one item; `lib.optionals` takes a list.
- `lib.optionalAttrs cond { ... }` → attrset or `{}`.
- `lib.optionalString cond "s"` → string or `""`.
- `lib.mkIf` / `lib.mkMerge` / `lib.mkDefault` / `lib.mkForce` / `lib.mkOrder` / `lib.mkBefore` / `lib.mkAfter` (module system only).
- `lib.attrsets.mapAttrs'` with `lib.nameValuePair` (not `lib.mkPair`).
- `lib.concatStringsSep`, `lib.concatMapStringsSep`, `lib.concatLines` (not `lib.join`).
- `lib.strings.hasPrefix` / `hasSuffix` / `removePrefix` / `splitString` / `replaceStrings` (builtin).
- `lib.lists.unique`, `lib.flatten`, `lib.filterAttrs`, `lib.genAttrs`, `lib.attrValues`, `builtins.attrNames`.
- `lib.hasAttrByPath`, `lib.getAttrFromPath`, `lib.attrByPath`, `lib.setAttrByPath`.
- `lib.versionAtLeast`, `lib.versionOlder`, `lib.getVersion`.
- `pkgs.writeShellScriptBin "name" ''...''` → package with `bin/name`.
- `pkgs.writeShellApplication { name; runtimeInputs; text; }` → adds PATH, `set -euo pipefail`, runs shellcheck.
- `pkgs.writeText`, `pkgs.writeTextFile`, `pkgs.runCommand "name" { } ''...''`, `pkgs.symlinkJoin`.
- `pkgs.fetchFromGitHub { owner; repo; rev or tag; hash; }` (`tag` is supported, use `rev` for commits).
- `pkgs.fetchurl { url; hash; }`; `pkgs.fetchzip` for archives.
- `stdenv.mkDerivation (finalAttrs: { ... })` → use `finalAttrs.version` instead of `rec`.
- `pkg.overrideAttrs (old: { ... })` changes derivation attrs; `pkg.override { dep = x; }` changes callPackage args.
- `lib.fakeHash` (SRI zero hash); `lib.fakeSha256` is legacy.

## Idioms
```nix
packages = with pkgs; [ git jq ] ++ lib.optionals stdenv.hostPlatform.isLinux [ inotify-tools ];
```
```nix
src = fetchFromGitHub { owner = "o"; repo = "r"; rev = "v${version}"; hash = lib.fakeHash; };
```
```nix
pkgs.writeShellApplication {
  name = "hello"; runtimeInputs = [ pkgs.jq ];
  text = ''echo "''${1:-world}" | jq -R .'';
}
```
```nix
outputs = { nixpkgs, ... }: let
  systems = [ "x86_64-linux" "aarch64-linux" ];
  forAll = f: nixpkgs.lib.genAttrs systems (s: f nixpkgs.legacyPackages.${s});
in { formatter = forAll (pkgs: pkgs.nixfmt-tree); devShells = forAll (pkgs: { default = pkgs.mkShell { packages = [ pkgs.hello ]; }; }); };
```

## Tooling
- `nix build .#pkg` / `nix build .#pkg -L` (show build logs) / `nix log /nix/store/...drv`
- `nix run .#app -- args`, `nix shell nixpkgs#jq`, `nix develop` (devShells.default)
- `nix flake update` (all inputs) / `nix flake update nixpkgs` (one input)
- `nix flake check`, `nix flake show`, `nix flake metadata`
- `nix eval .#foo --json`, `nix eval --expr '1 + 1'`, `nix repl` then `:lf .`
- `nix fmt` runs the flake `formatter` output; `nixfmt file.nix` formats one file
- Lint: `statix check`, dead code: `deadnix`; LSP: `nixd` or `nil`
- Hash of URL: `nix store prefetch-file URL`; GitHub: `nurl https://github.com/o/r v1.0`
- `nix why-depends .#a nixpkgs#b`, `nix path-info -rS .#pkg`
- Garbage collect: `nix-collect-garbage -d` (or `nix store gc`)
