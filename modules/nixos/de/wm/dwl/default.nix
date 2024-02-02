{ config, pkgs, lib, ... }:

let
  cfg = config._custom.de.dwl;
  inherit (config._custom.globals) themeColors cursor userName;
  inherit (lib._custom) unwrapHex;

  dwl-waybar = pkgs.writeTextFile {
    name = "dwl-waybar";
    destination = "/bin/dwl-waybar";
    executable = true;
    text = builtins.readFile ./scripts/dwl-waybar.sh;
  };
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
          version = "bfd95f07624418d7d3522e2dc41ad44f5aa7c207";
          # install patched dwl
          src = prev.fetchFromGitea {
            domain = "codeberg.org";
            owner = "wochap";
            repo = "dwl";
            rev = version;
            hash = "sha256-rjRuzZsDdXv8vYGqWsKEQt0ORPMYpkNhmBNl/eyKVxk=";
          };

          # add display manager session
          postInstall = let
            dwlSession = ''
              [Desktop Entry]
              Name=dwl
              Comment=dwl for Wayland
              Exec=dwl > /home/${userName}/.cache/dwltags
              Type=Application
            '';
          in ''
            mkdir -p $out/share/wayland-sessions
            echo "${dwlSession}" > $out/share/wayland-sessions/dwl.desktop
          '';
          passthru.providedSessions = [ "dwl" ];
        });
      })
    ];

    environment = {
      systemPackages = with pkgs; [
        dwl-waybar # script that prints dwl state
        dwl-final

        wlopm # toggle screen
        wlrctl # control keyboard, mouse and wm from cli

        # for testing vanilla dwl
        bemenu
        foot
      ];

      sessionVariables = lib.mkIf cfg.isDefault {
        XDG_CURRENT_DESKTOP = "wlroots";
        XDG_SESSION_DESKTOP = "dwl";
      };
    };

    _custom.wm.greetd.cmd =
      lib.mkIf cfg.isDefault "dwl > /home/${userName}/.cache/dwltags";

    xdg.portal.config.dwl.default = [ "wlr" "gtk" ];

    services.xserver.displayManager.sessionPackages = [ dwl-final ];

    _custom.hm = lib.mkIf cfg.isDefault {
      programs.waybar = {
        settings.mainBar = lib.mkMerge ([{
          modules-left = (builtins.map (i: "custom/dwl_tag#${toString i}")
            (builtins.genList (i: i) 9))
            ++ [ "custom/dwl_layout" "custom/dwl_mode" "keyboard-state" ];
          modules-center = [ "custom/dwl_title" ];
          "custom/dwl_layout" = {
            exec = "dwl-waybar '' layout";
            format = "{}";
            escape = true;
            return-type = "json";
          };
          "custom/dwl_title" = {
            exec = "dwl-waybar '' title";
            format = "{}";
            escape = true;
            return-type = "json";
            max-length = 50;
          };
          "custom/dwl_mode" = {
            exec = "dwl-waybar '' mode";
            format = "{}";
            escape = true;
            return-type = "json";
          };
        }] ++ (builtins.map (i: {
          "custom/dwl_tag#${toString i}" = {
            exec = "dwl-waybar '' ${toString i}";
            format = "{}";
            return-type = "json";
          };
        }) (builtins.genList (i: i) 9)));
      };

      services.swayidle.timeouts = lib.mkAfter [
        {
          timeout = 195;
          command = ''wlopm --off "*"'';
          resumeCommand = ''wlopm --on "*"'';
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
