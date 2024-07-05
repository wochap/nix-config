{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.desktop.dwl;
  inherit (config._custom.globals) themeColors cursor userName configDirectory;
  inherit (lib._custom) unwrapHex;

  dwl-state =
    pkgs.writeScriptBin "dwl-state" (builtins.readFile ./scripts/dwl-state.sh);
  dwl-final = (pkgs.dwl.override {
    conf = builtins.readFile (pkgs.substituteAll {
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
  dwl-save-logs-str = ''
    errlogs_path="/home/${userName}/.cache/dwlstderrlogs"
    logs_path="/home/${userName}/.cache/dwllogs"
    timestamp=$(date +"%a-%d-%b-%H:%M-%Y")

    if [[ -f "$errlogs_path" ]]; then
      mv "$errlogs_path" "''${errlogs_path}_''${timestamp}"
    fi

    if [[ -f "$logs_path" ]]; then
      mv "$logs_path" "''${logs_path}_''${timestamp}"
    fi
  '';
  stop-targets-str = ''
    pid=$!
    wait $pid
    systemctl --user stop graphical-session.target --quiet
    systemctl --user stop wayland-session.target --quiet
  '';
  dwl-start = pkgs.writeScriptBin "dwl-start" ''
    ${dwl-save-logs-str}
    dwl -d "$@" > /home/${userName}/.cache/dwllogs 2> /home/${userName}/.cache/dwlstderrlogs &
    ${stop-targets-str}
  '';
  dwl-start-with-dgpu-port = pkgs.writeScriptBin "dwl-start-with-dgpu-port" ''
    ${dwl-save-logs-str}
    # NOTE: This is specific for glegion host with nvidia
    # so I can use HDMI port connected directly to dGPU
    unset WLR_RENDERER; unset __EGL_VENDOR_LIBRARY_FILENAMES; WLR_DRM_DEVICES="$IGPU_CARD:$DGPU_CARD" dwl -d "$@" > /home/${userName}/.cache/dwllogs 2> /home/${userName}/.cache/dwlstderrlogs &
    ${stop-targets-str}
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
          version = "ce2dd66ff7995ff390a39a82ebf5320a7886a16e";
          src = prev.fetchFromGitHub {
            owner = "wochap";
            repo = "dwl";
            rev = version;
            hash = "sha256-9/svJidr4qgugRGPaaMfgAwCyclF5HZMJQj/ODNgouw=";
          };
          buildInputs = oldAttrs.buildInputs ++ (with pkgs; [
            inputs.scenefx.packages."${system}".scenefx
            libGL
          ]);
        });
      })
    ];

    environment.systemPackages = with pkgs; [
      dwl-final
      dwl-start
      dwl-start-with-dgpu-port
      dwl-state # script that prints dwl state

      # for testing vanilla dwl
      bemenu
    ];

    _custom.desktop.greetd.cmd =
      lib.mkIf cfg.isDefault "${dwl-start}/bin/dwl-start";
    environment.etc = {
      "greetd/environments".text = lib.mkAfter ''
        dwl
        dwl-start
        dwl-start-with-dgpu-port
      '';
      "greetd/sessions/dwl.dekstop".text = ''
        [Desktop Entry]
        Name=dwl
        Comment=dwm for Wayland
        Exec=dwl-start
        Type=Application
      '';
      "greetd/sessions/dwl-dgpu-port.dekstop".text = ''
        [Desktop Entry]
        Name=dwl-dgpu-port
        Comment=dwm for Wayland
        Exec=dwl-start-with-dgpu-port
        Type=Application
      '';
    };

    xdg.portal.config.dwl.default = [ "wlr" "gtk" ];

    _custom.desktop.ags.systemdEnable = lib.mkIf cfg.isDefault true;
    _custom.desktop.ydotool.systemdEnable = lib.mkIf cfg.isDefault true;

    _custom.hm = {
      xdg.configFile = {
        "scripts/dwl-dp.sh" = {
          source = ./scripts/dwl-dp.sh;
          executable = true;
        };
        "scripts/dwl-glegion-stream.sh" = {
          source = ./scripts/dwl-glegion-stream.sh;
          executable = true;
        };
        "scripts/dwl-se.sh" = {
          source = ./scripts/dwl-se.sh;
          executable = true;
        };
        "scripts/dwl-timers.sh" = {
          source = ./scripts/dwl-timers.sh;
          executable = true;
        };
        "scripts/dwl-vtm.sh" = {
          source = ./scripts/dwl-vtm.sh;
          executable = true;
        };

        "remmina/glegion.remmina".source =
          lib._custom.relativeSymlink configDirectory
          ./dotfiles/glegion.remmina;
      };
    };
  };
}
