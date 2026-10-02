{
  pkgs ? (builtins.getFlake "nixpkgs").legacyPackages.${builtins.currentSystem},
}:
let
  inherit (pkgs) lib;
  set = import ../default.nix { inherit pkgs; };
  inherit (set) greet greet-dev run-greet;
  srcEntries = if greet ? src then builtins.attrNames (builtins.readDir greet.src) else null;
  propagated = (greet.propagatedBuildInputs or [ ]) ++ (greet.propagatedNativeBuildInputs or [ ]);
  checks = {
    "greet.pname" = greet.pname == "greet";
    "greet.version" = greet.version == "1.2.0";
    "greet.name" = greet.name == "greet-1.2.0";
    "greet.src only contains greet.sh" = srcEntries == [ "greet.sh" ];
    "greet.meta.mainProgram" = (greet.meta.mainProgram or null) == "greet";
    "greet.meta.license is mit" = (greet.meta.license or null) == lib.licenses.mit;
    "greet.meta.description" =
      builtins.isString (greet.meta.description or null) && greet.meta.description != "";
    "lib.getExe greet" = lib.hasSuffix "/bin/greet" (lib.getExe greet);
    "jq not propagated" = !(builtins.any (p: (p.pname or "") == "jq") propagated);
    "greet-dev.version" = greet-dev.version == "1.2.0-dev";
    "greet-dev.name" = greet-dev.name == "greet-1.2.0-dev";
    "run-greet is a derivation" = lib.isDerivation run-greet;
  };
  failed = builtins.attrNames (lib.filterAttrs (_: ok: !ok) checks);
in
if failed == [ ] then
  "ok"
else
  throw ("eval checks failed:\n" + lib.concatMapStringsSep "\n" (n: "  FAIL ${n}") failed)
