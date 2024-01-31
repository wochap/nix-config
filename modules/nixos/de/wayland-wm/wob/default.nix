{ config, pkgs, lib, ... }:

let
  cfg = config._custom.waylandWm;
  userName = config._userName;
  inherit (config._custom.globals) themeColors;
  inherit (lib._custom) unwrapHex;
  wob-osd = pkgs.writeTextFile {
    name = "wob-osd";
    destination = "/bin/wob-osd";
    executable = true;
    text = builtins.readFile ./scripts/wob-osd.sh;
  };
in {
  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        wob = prev.wob.overrideAttrs (_: {
          version = "75a65e6c33e916a5453d705ed5b3b21335587631";
          src = pkgs.fetchFromGitHub {
            owner = "francma";
            repo = "wob";
            rev = "75a65e6c33e916a5453d705ed5b3b21335587631";
            sha256 = "sha256-N6+UUCRerzswbU5XpoNeG6Qu//QSyXD4mTIXwCPXMsU=";
          };

          buildInputs = with pkgs; [
            inih
            wayland
            wayland-protocols
            pixman
            cmocka
            libseccomp
          ];
        });
      })
    ];

    home-manager.users.${userName} = {
      home = { packages = with pkgs; [ wob wob-osd ]; };

      xdg.configFile = {
        "wob/wob.ini".text = ''
          ${builtins.readFile ./dotfiles/wob.ini}

          ; `background_color` Background color, in RRGGBB[AA] format.
          background_color = ${unwrapHex themeColors.background}ff
          ; `bar_color` Bar color, in RRGGBB[AA] format.
          bar_color = ${unwrapHex themeColors.primary}ff
          ; `border_color` Border color, in RRGGBB[AA] format.
          border_color = ${unwrapHex themeColors.selection}ff

          ; `overflow_background_color` Overflow background color, in RRGGBB[AA] format.
          overflow_background_color = ${unwrapHex themeColors.background}ff
          ; `overflow_bar_color` Overflow bar color, in RRGGBB[AA] format.
          overflow_bar_color = ${unwrapHex themeColors.pink}ff
          ; `overflow_border_color` Overflow border color, in RRGGBB[AA] format.
          overflow_border_color = ${unwrapHex themeColors.selection}ff

          [style.muted]
          bar_color = ${unwrapHex themeColors.comment}ff
          overflow_bar_color = ${unwrapHex themeColors.comment}ff
        '';
      };

      systemd.user = {
        services.wob = {
          Unit = {
            Description =
              "A lightweight overlay volume/backlight/progress/anything bar for Wayland";
            Documentation = "man:wob(1)";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
            ConditionEnvironment = [ "WAYLAND_DISPLAY" ];
          };

          Service = {
            ExecStart = "${pkgs.wob}/bin/wob";
            StandardInput = "socket";
          };

          Install = { WantedBy = [ "graphical-session.target" ]; };
        };

        sockets.wob = {
          Socket = {
            ListenFIFO = "%t/wob.sock";
            SocketMode = "0600";
            RemoveOnStop = "on";
            # If wob exits on invalid input, systemd should NOT shove following input right back into it after it restarts
            FlushPending = "yes";
          };

          Install = { WantedBy = [ "sockets.target" ]; };
        };
      };
    };
  };
}
