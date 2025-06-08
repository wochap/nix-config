{ config, pkgs, lib, inputs, system, ... }:

let
  cfg = config._custom.desktop.dwl;
  inherit (config._custom.globals) themeColors cursor userName configDirectory;
  inherit (lib._custom) unwrapHex;

  scenefx-final = inputs.scenefx.packages."${system}".scenefx;
  dwl-state =
    pkgs.writeScriptBin "dwl-state" (builtins.readFile ./scripts/dwl-state.sh);
  dwl-final = (pkgs.dwl.override {
    wlroots = pkgs.wlroots_0_18;
    configH = builtins.readFile (pkgs.replaceVars ./dotfiles/config.def.h {
      # primary = unwrapHex themeColors.primary;
      # lavender = unwrapHex themeColors.lavender;
      base = unwrapHex themeColors.base;
      # mantle = unwrapHex themeColors.mantle;
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
            "3efac0422cd9083160b7bfc7563f053084e8d38f"; # v0.8-a/patches-28-mar-2025
          src = prev.fetchFromGitHub {
            owner = "wochap";
            repo = "dwl";
            rev = version;
            hash = "sha256-9cqdinHn4Cyl+RjiQ6fpRUnkV6P2d0iNYMLY4ocU6jI=";
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
      dwl-start
    ];

    environment.etc."greetd/environments".text = lib.mkAfter ''
      dwl
      tee
    '';

    _custom.desktop.uwsm.waylandCompositors = {
      dwl = {
        prettyName = "dwl";
        comment = "dwm for Wayland";
        binPath = "/run/current-system/sw/bin/dwl-start";
        xdgCurrentDesktop = "dwl";
      };
      dwl-dgpu = {
        prettyName = "dwl-dgpu";
        comment = "dwm for Wayland";
        binPath = "/run/current-system/sw/bin/dwl-start";
        xdgCurrentDesktop = "dwl";
      };
    };

    xdg.portal.config.dwl.default = [ "wlr" "gtk" ];

    _custom.desktop.ags.systemdEnable = lib.mkIf cfg.isDefault true;
    _custom.desktop.ydotool.systemdEnable = lib.mkIf cfg.isDefault true;

    _custom.hm = {
      home.file.".cache/dwl/.keep".text = "";

      xdg = {
        configFile = {
          "scripts/dwl" = {
            recursive = true;
            source = ./scripts/automation;
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
