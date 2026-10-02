# Nix: countBy

Write `count-by.nix`. It must evaluate to a function that takes `{ lib }` (nixpkgs lib)
and returns `countBy`:

```nix
countBy = import ./count-by.nix { inherit lib; };
countBy f list   # => attrset
```

- `f` maps each element of `list` to a string key.
- The result maps every key produced by `f` to the number of elements that produced it.
- Keys that no element produces must not appear. An empty list gives `{ }`.
- Elements can be of any type (ints, strings, attrsets, lists).

Examples:

```nix
countBy (x: if x > 0 then "pos" else "neg") [ 1 (-2) 3 ]  # => { neg = 1; pos = 2; }
countBy (s: s) [ "a" "b" "a" "a" ]                        # => { a = 3; b = 1; }
countBy (p: p.lang) [ { lang = "nix"; } { lang = "go"; } ] # => { go = 1; nix = 1; }
countBy toString [ ]                                      # => { }
```

Tests live in `tests/test.nix` and are run with
`nix eval --impure --expr 'import ./tests/test.nix'` (nixpkgs comes from the flake registry).
The code must pass `nixfmt --check`, `statix check` and `deadnix --fail`.
