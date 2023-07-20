{ config, pkgs, lib, ... }:

let
  theme = config._theme;

  river-focus-toggle = pkgs.writeTextFile {
    name = "river-focus-toggle";
    destination = "/bin/river-focus-toggle";
    executable = true;

    text = builtins.readFile ./river-focus-toggle.sh;
  };
in { inherit river-focus-toggle; }
