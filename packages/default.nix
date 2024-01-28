{ pkgs, lib, inputs, ... }:

let
  localPkgs = rec {
    # lib
    # TODO: move to custom lib
    unwrapHex = str: builtins.substring 1 (builtins.stringLength str) str;
    fromYAML = pkgs.callPackage ./from-yaml { };
    generate-ssc = pkgs.callPackage ./generate-ssc { };
    # https://github.com/nix-community/home-manager/issues/257#issuecomment-1646557848
    runtimePath = runtimeRoot: path:
      let
        rootStr = toString inputs.self;
        pathStr = toString path;
      in assert lib.assertMsg (lib.hasPrefix rootStr pathStr)
        "${pathStr} does not start with ${rootStr}";
      runtimeRoot + lib.removePrefix rootStr pathStr;

    # packages
    advcpmv = pkgs.callPackage ./advcpmv { };
    dunst-nctui = pkgs.callPackage ./dunst-nctui { };
    dwl-state = pkgs.callPackage ./dwl-state { };
    generated-ssc = generate-ssc { domain = "wochap.local"; };
    interception-both-shift-capslock =
      pkgs.callPackage ./interception-both-shift-capslock { };
    mailnotify = pkgs.callPackage ./mailnotify { };
    mangadesk = pkgs.callPackage ./mangadesk { };
    matcha = pkgs.callPackage ./matcha { };
    offlinemsmtp = pkgs.callPackage ./offlinemsmtp { };
    ollama-webui = pkgs.callPackage ./ollama-webui { };
    ptsh = pkgs.callPackage ./ptsh { };
    tela-icon-theme = pkgs.callPackage ./tela-icon-theme { };
    usbfluxd = pkgs.callPackage ./usbfluxd { };
    customNodePackages = lib.dontRecurseIntoAttrs
      (pkgs.callPackage ./custom-node-packages {
        nodejs = pkgs.prevstable-nodejs.nodejs_20;
      });
  };
in {
  config = { nixpkgs.overlays = [ (final: prev: { _custom = localPkgs; }) ]; };
}
