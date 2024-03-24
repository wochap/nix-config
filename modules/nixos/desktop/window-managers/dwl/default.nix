{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.dwl;
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
  options._custom.desktop.dwl = {
    enable = lib.mkEnableOption { };
    isDefault = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        dwl = prev.dwl.overrideAttrs (oldAttrs: rec {
          version = "122819121cda8cbe2d7dc785911353e1da874917";
          src = prev.fetchFromGitHub {
            owner = "wochap";
            repo = "dwl";
            rev = version;
            hash = "sha256-4x+I3U8TReTxv7wmGFsgY7v87ZA1/5/RZ005KKysm/o=";
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

    _custom.desktop.waybar.systemdEnable = lib.mkIf cfg.isDefault false;

    _custom.desktop.greetd.cmd = lib.mkIf cfg.isDefault
      "dwl > /home/${userName}/.cache/dwltags 2> /home/${userName}/.cache/dwlstderrlog";
    _custom.desktop.ags.systemdEnable = lib.mkIf cfg.isDefault true;
    _custom.desktop.ydotool.systemdEnable = lib.mkIf cfg.isDefault true;

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
