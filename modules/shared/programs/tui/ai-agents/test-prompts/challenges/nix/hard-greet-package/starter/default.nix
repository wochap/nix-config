{ pkgs }:
let
  greet = pkgs.callPackage ./package.nix { };
in
{
  inherit greet;
  # TODO: see PROMPT.md
  greet-dev = greet;
  run-greet = greet;
}
