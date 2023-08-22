{ config, pkgs, lib, ... }:

let
  river-focus-toggle = pkgs.writeTextFile {
    name = "river-focus-toggle";
    destination = "/bin/river-focus-toggle";
    executable = true;

    text = builtins.readFile ./river-focus-toggle.sh;
  };
in { inherit river-focus-toggle; }
