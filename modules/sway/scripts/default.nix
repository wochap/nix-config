{ config, pkgs, lib, ... }:

let
  theme = config._theme;

  sway-focus-toggle = pkgs.writeTextFile {
    name = "sway-focus-toggle";
    destination = "/bin/sway-focus-toggle";
    executable = true;

    text = builtins.readFile ./sway-focus-toggle.sh;
  };

in { inherit sway-focus-toggle; }
