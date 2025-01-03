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
  dwl-save-logs-str = # bash
    ''
      errlogs_path="/home/${userName}/.cache/dwl/stderrlogs"
      logs_path="/home/${userName}/.cache/dwl/logs"
      timestamp=$(date +"%a-%d-%b-%H:%M-%Y")

      if [[ -f "$errlogs_path" ]]; then
        mv "$errlogs_path" "''${errlogs_path}_''${timestamp}"
      fi

      if [[ -f "$logs_path" ]]; then
        mv "$logs_path" "''${logs_path}_''${timestamp}"
      fi
    '';
  stop-targets-str = # bash
    ''
      pid=$!
      wait $pid
      systemctl --user stop graphical-session.target --quiet
      systemctl --user stop wayland-session.target --quiet
    '';
  dwl-start = pkgs.writeScriptBin "dwl-start" ''
    ${dwl-save-logs-str}
    dwl -d "$@" > "$logs_path" 2> "$errlogs_path" &
    ${stop-targets-str}
  '';
  dwl-start-with-dgpu-port = pkgs.writeScriptBin "dwl-start-with-dgpu-port" ''
    ${dwl-save-logs-str}
    # NOTE: This is specific for glegion host with nvidia
    # so I can use HDMI port connected directly to dGPU
    unset WLR_RENDERER; unset __EGL_VENDOR_LIBRARY_FILENAMES; WLR_DRM_DEVICES="$IGPU_CARD:$DGPU_CARD" dwl -d "$@" > "$logs_path" 2> "$errlogs_path" &
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
          version = "75598dd0"; # v0.8-a/patches-02-aug-2024
          src = prev.fetchFromGitHub {
            owner = "wochap";
            repo = "dwl";
            rev = version;
            hash = "sha256-yJPZQcKFub78S++n6q6dO5aeZ9+CO0GP7rFYRMWCZ4k=";
          };
          buildInputs = with pkgs; oldAttrs.buildInputs ++ [
            scenefx-final
            libGL
          ];
          # enable debug symbols for better backtrace
          separateDebugInfo = true;
          dontStrip = true;
        });
      })
    ];

    environment.systemPackages = with pkgs; [
      dwl-final
      dwl-start
      dwl-start-with-dgpu-port
      dwl-state # script that prints dwl state
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
      home.file.".cache/dwl/.keep".text = "";

      xdg.configFile = {
        "scripts" = {
          recursive = true;
          # TODO: skip dwl-state.sh
          source = ./scripts;
        };

        "remmina/glegion.remmina".source =
          lib._custom.relativeSymlink configDirectory
          ./dotfiles/glegion.remmina;
      };
    };
  };
}
