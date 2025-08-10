{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.foot;
  inherit (config._custom.globals) themeColors configDirectory;
  iniFormat = pkgs.formats.ini { };
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
    _custom.programs.foot.settings = {
      main = {
        shell = "${pkgs.tmux}/bin/tmux";
        include =
          "${lib._custom.relativeSymlink configDirectory ./dotfiles/foot.ini}";
      };
      cursor.color = "${lib._custom.unwrapHex themeColors.base} ${
          lib._custom.unwrapHex themeColors.green
        }";
    };

    _custom.hm = {
      home.packages = with pkgs; [ foot libsixel ];

      xdg.configFile."foot/foot.ini".text = ''
        ${builtins.readFile
        "${inputs.catppuccin-foot}/themes/catppuccin-${themeColors.flavour}.ini"}
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
