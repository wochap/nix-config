{ pkgs, lib, ... }:

let
  customPkgs = rec {
    tmuxinator = pkgs.callPackage ./tmuxinator { };
    pseint = pkgs.callPackage ./pseint { };
    fcitx5-fbterm = pkgs.callPackage ./fcitx5-fbterm { };
    clipboard-sync = pkgs.callPackage ./clipboard-sync { };
    advcpmv = pkgs.callPackage ./advcpmv { };
    dunst-nctui = pkgs.callPackage ./dunst-nctui { };
    generate-ssc = pkgs.callPackage ./generate-ssc { };
    gh-prx = pkgs.callPackage ./gh-prx { };
    wochap-ssc = generate-ssc {
      domain = "wochap.local";
      # NOTE: don't use 127.0.0.1 to prevent conflicts with localhost
      address = "127.0.1.1";
    };
    interception-both-shift-capslock =
      pkgs.callPackage ./interception-both-shift-capslock { };
    mailnotify = pkgs.callPackage ./mailnotify { };
    mangadesk = pkgs.callPackage ./mangadesk { };
    offlinemsmtp = pkgs.callPackage ./offlinemsmtp { };
    ollama-webui-lite = pkgs.callPackage ./ollama-webui-lite { };
    pam-autologin = pkgs.callPackage ./pam-autologin { };
    ptsh = pkgs.callPackage ./ptsh { };
    tela-icon-theme = pkgs.callPackage ./tela-icon-theme { };
    usbfluxd = pkgs.callPackage ./usbfluxd { };
    nodePackages = lib.dontRecurseIntoAttrs (pkgs.callPackage ./node-packages {
      nodejs = pkgs.prevstable-nodejs.nodejs_20;
    });
    pythonPackages =
      lib.dontRecurseIntoAttrs (pkgs.callPackage ./python-packages { });
    wlroots = pkgs.callPackage ./wlroots { };
  };
in {
  config = { nixpkgs.overlays = [ (final: prev: { _custom = customPkgs; }) ]; };
}
