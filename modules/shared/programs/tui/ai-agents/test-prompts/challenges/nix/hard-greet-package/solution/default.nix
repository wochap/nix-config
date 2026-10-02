{ pkgs }:
let
  greet = pkgs.callPackage ./package.nix { };
in
{
  inherit greet;

  greet-dev = greet.overrideAttrs {
    version = "1.2.0-dev";
    __intentionallyOverridingVersion = true;
  };

  run-greet = pkgs.writeShellApplication {
    name = "hello-all";
    text = ''
      for name in "$@"; do
        ${pkgs.lib.getExe greet} "$name"
      done
    '';
  };
}
