{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.foot;
  inherit (config._custom.globals)
    themeColorsLight themeColorsDark configDirectory preferDark;

  iniFormat = pkgs.formats.ini { };
  catppuccin-foot-light-theme-path =
    "${inputs.catppuccin-foot}/themes/catppuccin-${themeColorsLight.flavour}.ini";
  catppuccin-foot-dark-theme-path =
    "${inputs.catppuccin-foot}/themes/catppuccin-${themeColorsDark.flavour}.ini";
in {
  options._custom.programs.foot = {
    enable = lib.mkEnableOption { };
    systemdEnable = lib.mkEnableOption { };
    settings = lib.mkOption {
      type = iniFormat.type;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        foot = prev.foot.overrideAttrs (oldAttrs: rec {
          version = "72d9a13c0c6b6ee4b56a38f508c2e8d5c56616b5";
          src = pkgs.fetchFromGitea {
            domain = "codeberg.org";
            owner = "dnkl";
            repo = "foot";
            rev = version;
            hash = "sha256-cUUoAVBtlhnZJWfuCYqHjjYKIpKf9JBHcE5YCi5WscI=";
          };
        });
      })
    ];

    _custom.programs.foot.settings = {
      main = {
        shell = lib.mkIf config._custom.programs.tmux.enable
          "${config._custom.programs.tmux.package}/bin/tmux";
        include =
          "${lib._custom.relativeSymlink configDirectory ./dotfiles/foot.ini}";
        initial-color-theme = if preferDark then 2 else 1;
      };
      colors.cursor = "${lib._custom.unwrapHex themeColorsLight.base} ${
          lib._custom.unwrapHex themeColorsLight.green
        }";
      colors2.cursor = "${lib._custom.unwrapHex themeColorsDark.base} ${
          lib._custom.unwrapHex themeColorsDark.green
        }";
    };

    _custom.hm = {
      home.packages = with pkgs; [ foot libsixel ];

      xdg.configFile."foot/foot.ini".text = ''
        # themes
        ${builtins.readFile catppuccin-foot-light-theme-path}
        ${lib.strings.replaceStrings [ "[colors]" ] [ "[colors2]" ]
        (builtins.readFile catppuccin-foot-dark-theme-path)}

        # nixos options
        ${builtins.readFile
        (iniFormat.generate "foot.ini" config._custom.programs.foot.settings)}
      '';

      systemd.user.services.foot-server = lib.mkIf cfg.systemdEnable {
        Unit = {
          Description = "Foot terminal server mode";
          Documentation = "man:foot(1)";
          Requires = "%N.socket";
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          ExecStart = "${pkgs.foot}/bin/foot --server=3";
          UnsetEnvironment = "LISTEN_PID LISTEN_FDS LISTEN_FDNAMES";
          NonBlocking = true;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      systemd.user.sockets.foot-server = lib.mkIf cfg.systemdEnable {
        Socket.ListenStream = "%t/foot.sock";
        Unit = {
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
