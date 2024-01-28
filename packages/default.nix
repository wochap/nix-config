{ pkgs, lib, ... }:

let
  localPkgs = rec {
    unwrapHex = str: builtins.substring 1 (builtins.stringLength str) str;
    fromYAML = pkgs.callPackage ./from-yaml.nix { };
    generate-ssc = pkgs.callPackage ./generate-ssc.nix { };

    advcpmv = pkgs.callPackage ./advcpmv { };
    dunst-nctui = pkgs.callPackage ./dunst-nctui.nix { };
    dwl-state = pkgs.callPackage ./dwl-state.nix { };
    generated-ssc = generate-ssc { domain = "wochap.local"; };
    interception-both-shift-capslock =
      pkgs.callPackage ./interception-both-shift-capslock { };
    mailnotify = pkgs.callPackage ./mailnotify.nix { };
    mangadesk = pkgs.callPackage ./mangadesk.nix { };
    matcha = pkgs.callPackage ./matcha.nix { };
    offlinemsmtp = pkgs.callPackage ./offlinemsmtp.nix { };
    ollama-webui = pkgs.callPackage ./ollama-webui.nix { };
    ptsh = pkgs.callPackage ./ptsh { };
    tela-icon-theme = pkgs.callPackage ./tela-icon-theme { };
    usbfluxd = pkgs.callPackage ./usbfluxd.nix { };
    customNodePackages = lib.dontRecurseIntoAttrs
      (pkgs.callPackage ./custom-node-packages {
        nodejs = pkgs.prevstable-nodejs.nodejs_20;
      });
  };
in {
  config = { nixpkgs.overlays = [ (final: prev: { _custom = localPkgs; }) ]; };
}
