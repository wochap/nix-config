{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.programs.foot;
  inherit (config._custom.globals) themeColors;
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
    _custom.hm = {
      home.packages = with pkgs; [ foot ];

      xdg.configFile."foot/foot.ini".text = ''
        ${builtins.readFile ./dotfiles/foot.ini}
        ${builtins.readFile
        "${inputs.catppuccin-foot}/catppuccin-${themeColors.flavor}.ini"}
        ${builtins.readFile
        (iniFormat.generate "foot.ini" config._custom.programs.foot.settings)}
      '';

      systemd.user.services.foot-server = lib.mkIf cfg.systemdEnable
        (lib._custom.mkWaylandService {
          Unit = {
            Description = "foot server";
            Documentation = "man:foot(1)";
          };
          Service = {
            Type = "forking";
            PassEnvironment = [ "PATH" ];
            ExecStart = "${pkgs.foot}/bin/foot --server";
          };
        });
    };
  };
}
