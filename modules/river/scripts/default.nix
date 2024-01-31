{ config, pkgs, lib, ... }:

let
  river-focus-toggle = pkgs.writeTextFile {
    name = "river-focus-toggle";
    destination = "/bin/river-focus-toggle";
    executable = true;

    text = builtins.readFile ./river-focus-toggle.sh;
  };
  river-tag-overlay-custom = pkgs.writeTextFile {
    name = "river-tag-overlay-custom";
    destination = "/bin/river-tag-overlay-custom";
    executable = true;

    text = ''
      #!/usr/bin/env bash

      river-tag-overlay \
        --tag-amount 32 \
        --tags-per-row 8 \
        --timeout 300 \
        --anchors 0:1:1:1 \
        --margins 0:0:7:0
    '';
  };
in { inherit river-focus-toggle; }
