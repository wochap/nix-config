{ config, pkgs, lib, ... }:

let
  cfg = config._custom.de.dwl;
  inherit (config._custom.globals) themeColors cursor userName;
  inherit (lib._custom) unwrapHex;

  dwl-waybar = pkgs.writeScriptBin "dwl-waybar"
    (builtins.readFile ./scripts/dwl-waybar.sh);
  dwl-final = (pkgs.unstable.dwl.override {
    conf = builtins.readFile (pkgs.substituteAll {
      src = ./dotfiles/config.def.h;
      crust = unwrapHex themeColors.crust;
      primary = unwrapHex themeColors.primary;
      red = unwrapHex themeColors.red;
      selection = unwrapHex themeColors.selection;
      cursorName = cursor.name;
      cursorSize = toString cursor.size;
    });
  });
in {
  options._custom.de.dwl = {
    enable = lib.mkEnableOption { };
    isDefault = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        dwl = prev.dwl.overrideAttrs (oldAttrs: rec {
          version = "5f78b9bded462fc88c05b10388abd02295bc567b";
          src = prev.fetchFromGitHub {
            owner = "wochap";
            repo = "dwl";
            rev = version;
            hash = "sha256-FGC0XoyP8LXgiJqJJIQsD0coE8P7AeotgdejZpOXHpA=";
          };
          buildInputs = with pkgs; [
            pkgs._custom.scenefx

            # wlroots buildInputs
            libGL
            libcap
            libinput
            libpng
            libxkbcommon
            mesa
            pixman
            seatd
            vulkan-loader
            wayland
            wayland-protocols
            xorg.libX11
            xorg.xcbutilerrors
            xorg.xcbutilimage
            xorg.xcbutilrenderutil
            xorg.xcbutilwm
            xwayland
            ffmpeg
            hwdata
            libliftoff
            libdisplay-info
          ];
        });
      })
    ];

    environment.systemPackages = with pkgs; [
      dwl-waybar # script that prints dwl state
      dwl-final

      wlopm # toggle screen
      wlrctl # control keyboard, mouse and wm from cli

      # for testing vanilla dwl
      bemenu
      foot
    ];

    _custom.de.waybar.systemdEnable = lib.mkIf cfg.isDefault false;
    _custom.de.wob.enable = lib.mkIf cfg.isDefault false;

    _custom.de.greetd.cmd = lib.mkIf cfg.isDefault
      "dwl > /home/${userName}/.cache/dwltags 2> /home/${userName}/.cache/dwlstderrlog";
    _custom.de.ags.systemdEnable = lib.mkIf cfg.isDefault true;
    _custom.de.ydotool.systemdEnable = lib.mkIf cfg.isDefault true;

    _custom.hm = lib.mkIf cfg.isDefault {
      home.sessionVariables = {
        XDG_CURRENT_DESKTOP = "wlroots";
        XDG_SESSION_DESKTOP = "dwl";
      };

      xdg.configFile."scripts/dwl-vtm.sh" = {
        source = ./scripts/dwl-vtm.sh;
        executable = true;
      };

      services.swayidle.timeouts = lib.mkAfter [
        {
          timeout = 180;
          command =
            ''if ! pgrep swaylock; then chayang -d 5 && wlopm --off "*"; fi'';
          resumeCommand = ''if ! pgrep swaylock; then wlopm --on "*"; fi'';
        }
        {
          timeout = 15;
          command = ''if pgrep swaylock; then wlopm --off "*"; fi'';
          resumeCommand = ''if pgrep swaylock; then wlopm --on "*"; fi'';
        }
      ];
    };
  };
}
