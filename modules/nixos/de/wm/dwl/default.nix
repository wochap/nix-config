{ config, pkgs, lib, ... }:

let
  cfg = config._custom.de.dwl;
  inherit (config._custom.globals) themeColors cursor userName;
  inherit (lib._custom) unwrapHex;

  dwl-waybar = pkgs.writeScriptBin "dwl-waybar"
    (builtins.readFile ./scripts/dwl-waybar.sh);
  dwl-final = (pkgs.unstable.dwl.override {
    conf = ''
      ${builtins.readFile ./dotfiles/config.def.h}

      static const float bordercolor[] = COLOR(0x${
        unwrapHex themeColors.selection
      }ff);
      static const float borderscolor[] = COLOR(0x${
        unwrapHex themeColors.selection
      }00);
      static const float borderecolor[] = COLOR(0x${
        unwrapHex themeColors.selection
      }ff);
      static const float focuscolor[] = COLOR(0x${
        unwrapHex themeColors.primary
      }ff);
      static const float urgentcolor[] = COLOR(0x${
        unwrapHex themeColors.red
      }ff);
      static const char cursortheme[] = "${cursor.name}";
      static const unsigned int cursorsize = ${toString cursor.size};
    '';
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
          version = "a0dcf93cb0c6e9c55030a2aed9c2b1a25212dccf";
          # install patched dwl
          src = prev.fetchFromGitHub {
            owner = "wochap";
            repo = "dwl";
            rev = version;
            hash = "sha256-AD1R/z+RDUKF62DRpjJ44v2VtJw9xenl4nz1TUNG1XQ=";
          };
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
