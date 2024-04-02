{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.dwl;
  inherit (config._custom.globals) themeColors cursor userName;
  inherit (lib._custom) unwrapHex;

  dwl-state =
    pkgs.writeScriptBin "dwl-state" (builtins.readFile ./scripts/dwl-state.sh);
  dwl-final = (pkgs.dwl.override {
    conf = builtins.readFile (pkgs.substituteAll {
      src = ./dotfiles/config.def.h;
      border = unwrapHex themeColors.border;
      red = unwrapHex themeColors.red;
      shadow = unwrapHex themeColors.shadow;
      surface0 = unwrapHex themeColors.surface0;
      cursorName = cursor.name;
      cursorSize = toString cursor.size;
    });
  });
  dwl-start = pkgs.writeScriptBin "dwl-start" ''
    dwl > /home/${userName}/.cache/dwltags 2> /home/${userName}/.cache/dwlstderrlog
  '';
  dwl-start-with-dgpu-port = pkgs.writeScriptBin "dwl-start-with-dgpu-port" ''
    # NOTE: This is specific for glegion host with nvidia
    # so I can use HDMI port connected directly to dGPU
    unset WLR_RENDERER; unset __EGL_VENDOR_LIBRARY_FILENAMES; WLR_DRM_DEVICES="$IGPU_CARD:$DGPU_CARD" dwl > /home/${userName}/.cache/dwltags 2> /home/${userName}/.cache/dwlstderrlog
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
          version = "582febdd0d3ed7f372f431b572e9abdaf94e0937";
          src = prev.fetchFromGitHub {
            owner = "wochap";
            repo = "dwl";
            rev = version;
            hash = "sha256-7hidfUENmHT638ypdgoDGYB5xhcURFYrwpvYCM8kVlE=";
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
      dwl-state # script that prints dwl state
      dwl-final
      dwl-start
      dwl-start-with-dgpu-port

      wlopm # toggle screen
      wlrctl # control keyboard, mouse and wm from cli

      # for testing vanilla dwl
      bemenu
      foot
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
