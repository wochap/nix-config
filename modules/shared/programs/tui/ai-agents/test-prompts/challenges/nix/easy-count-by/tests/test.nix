let
  inherit ((builtins.getFlake "nixpkgs")) lib;
  countBy = import ../count-by.nix { inherit lib; };
  cases = [
    {
      name = "sign";
      got = countBy (x: if x > 0 then "pos" else "neg") [
        1
        (-2)
        3
      ];
      want = {
        neg = 1;
        pos = 2;
      };
    }
    {
      name = "identity";
      got = countBy (s: s) [
        "a"
        "b"
        "a"
        "a"
      ];
      want = {
        a = 3;
        b = 1;
      };
    }
    {
      name = "attrsets";
      got = countBy (p: p.lang) [
        { lang = "nix"; }
        { lang = "go"; }
        { lang = "nix"; }
      ];
      want = {
        go = 1;
        nix = 2;
      };
    }
    {
      name = "empty";
      got = countBy toString [ ];
      want = { };
    }
    {
      name = "single key";
      got = countBy (_: "all") (lib.range 1 50);
      want = {
        all = 50;
      };
    }
    {
      name = "keys with dots and dashes";
      got = countBy (x: x) [
        "a.b"
        "c-d"
        "a.b"
        ""
      ];
      want = {
        "a.b" = 2;
        "c-d" = 1;
        "" = 1;
      };
    }
    {
      name = "lists as elements";
      got = countBy (l: toString (builtins.length l)) [
        [ ]
        [ 1 ]
        [
          1
          2
        ]
        [ 3 ]
      ];
      want = {
        "0" = 1;
        "1" = 2;
        "2" = 1;
      };
    }
    {
      name = "parity";
      got = countBy (n: if lib.mod n 2 == 0 then "even" else "odd") (lib.range 0 9);
      want = {
        even = 5;
        odd = 5;
      };
    }
  ];
  failed = builtins.filter (c: c.got != c.want) cases;
  show = c: "FAIL ${c.name}: got ${builtins.toJSON c.got}, want ${builtins.toJSON c.want}";
in
if failed == [ ] then
  "ok: ${toString (builtins.length cases)} tests passed"
else
  throw ("\n" + lib.concatMapStringsSep "\n" show failed)
