{ config, pkgs, lib, inputs, system, ... }:

let
  cfg = config._custom.desktop.dwl;
  inherit (config._custom.globals) themeColors cursor userName configDirectory;
  inherit (lib._custom) unwrapHex;

  scenefx-final = inputs.scenefx.packages."${system}".scenefx;
  dwl-state =
    pkgs.writeScriptBin "dwl-state" (builtins.readFile ./scripts/dwl-state.sh);
  dwl-write-logs = pkgs.writeScriptBin "dwl-write-logs"
    (builtins.readFile ./scripts/dwl-write-logs.sh);
  dwl-final = (pkgs.dwl.override {
    wlroots = pkgs.wlroots_0_18;
    configH = builtins.readFile (pkgs.substituteAll {
      src = ./dotfiles/config.def.h;
      primary = unwrapHex themeColors.primary;
      lavender = unwrapHex themeColors.lavender;
      base = unwrapHex themeColors.base;
      mantle = unwrapHex themeColors.mantle;
      crust = unwrapHex themeColors.crust;
      border = unwrapHex themeColors.border;
      red = unwrapHex themeColors.red;
      shadow = unwrapHex themeColors.shadow;
      surface0 = unwrapHex themeColors.surface0;
      cursorName = cursor.name;
      cursorSize = toString cursor.size;
    });
  });
  dwl-start = pkgs.writeScriptBin "dwl-start"
    # bash
    ''
      #!/usr/bin/env bash

      logs_path="/home/${userName}/.cache/dwl/logs"
      if [[ -f "$logs_path" ]]; then
        rm "$logs_path"
      fi
      dwl | tee -a "$logs_path"
    '';
  greetd-default-cmd =
    "uwsm start -S -F -N dwl -D dwl -- /run/current-system/sw/bin/dwl-start";
in {
  options._custom.desktop.dwl = {
    enable = lib.mkEnableOption { };
    isDefault = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        dwl = prev.dwl.overrideAttrs (oldAttrs: rec {
          version =
            "48e269e80b34efdd6176925d79e0f82625ae5c1e"; # v0.8-a/patches-02-aug-2024
          src = prev.fetchFromGitHub {
            owner = "wochap";
            repo = "dwl";
            rev = version;
            hash = "sha256-sgIbALKOaEflZUs3NHNZl3oofU+UnEcOzVN6QyFg56k=";
          };
          buildInputs = with pkgs;
            oldAttrs.buildInputs ++ [ scenefx-final libGL ];
          # enable debug symbols for better backtrace
          separateDebugInfo = true;
          dontStrip = true;
        });
      })
    ];

    environment.systemPackages = with pkgs; [
      dwl-final
      dwl-state # script that prints dwl state
      dwl-write-logs # script that copies logs from journal to file
      dwl-start
    ];

    _custom.desktop.greetd.cmd = lib.mkIf cfg.isDefault greetd-default-cmd;
    environment.etc = {
      "greetd/environments".text = lib.mkAfter ''
        dwl
        tee
      '';
      "greetd/sessions/dwl-uwsm.dekstop".text = ''
        [Desktop Entry]
        Name=dwl (UWSM)
        Comment=dwm for Wayland
        Exec=${greetd-default-cmd}
        Type=Application
      '';
      "greetd/sessions/dwl-dgpu-uwsm.dekstop".text = ''
        [Desktop Entry]
        Name=dwl-dgpu (UWSM)
        Comment=dwm for Wayland
        Exec=uwsm start -S -F -N dwl-dgpu -D dwl -- /run/current-system/sw/bin/dwl-start
        Type=Application
      '';
    };

    xdg.portal.config.dwl.default = [ "wlr" "gtk" ];

    _custom.desktop.ags.systemdEnable = lib.mkIf cfg.isDefault true;
    _custom.desktop.ydotool.systemdEnable = lib.mkIf cfg.isDefault true;

    _custom.hm = {
      home.file.".cache/dwl/.keep".text = "";

      xdg = {
        configFile = {
          "scripts" = {
            recursive = true;
            # TODO: skip dwl-state.sh
            source = ./scripts;
          };

          "remmina/glegion.remmina".source =
            lib._custom.relativeSymlink configDirectory
            ./dotfiles/glegion.remmina;

          # TODO: WLR_DRM_DEVICES isn't being passed to wm
          "uwsm/env-dwl-dgpu".text = ''
            # env variables for starting hyprland with discrete gpu
            # NOTE: This is specific to glegion host with nvidia
            # to enable using the HDMI port connected directly to the dGPU
            export WLR_RENDERER=
            export __EGL_VENDOR_LIBRARY_FILENAMES=
            export WLR_DRM_DEVICES=$IGPU_CARD:$DGPU_CARD
          '';
        };
      };
    };
  };
}
