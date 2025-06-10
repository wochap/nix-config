{ config, lib, inputs, pkgs, system, ... }:

let
  cfg = config._custom.desktop.ags;
  inherit (config._custom.globals) configDirectory userName;
  hmConfig = config.home-manager.users.${userName};
  agsFinal = inputs.ags.packages.${system}.default;
  capslock =
    pkgs.writeScriptBin "capslock" (builtins.readFile ./scripts/capslock.sh);
  progress-osd = pkgs.writeScriptBin "progress-osd"
    (builtins.readFile ./scripts/progress-osd.sh);
  toggle-bars = pkgs.writeScriptBin "toggle-bars"
    (builtins.readFile ./scripts/toggle-bars.sh);
  wireguard-status = pkgs.writeScriptBin "wireguard-status"
    (builtins.readFile ./scripts/wireguard-status.sh);
in {
  options._custom.desktop.ags = {
    enable = lib.mkEnableOption { };
    systemdEnable = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    security.pam.services.ags = { };

    _custom.hm = {
      imports = [ inputs.ags.homeManagerModules.default ];

      home.packages = [ capslock progress-osd toggle-bars wireguard-status ];

      programs.ags = {
        enable = true;
        package = agsFinal;
      };

      # Install custom icon theme, for taskbar
      xdg.dataFile."icons/Reversal-Extra".source = "${inputs.reversal-extra}";

      xdg.configFile."ags".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles;

      systemd.user.services.ags = lib.mkIf cfg.systemdEnable
        (lib._custom.mkWaylandService {
          Unit = {
            Description = "A customizable and extensible shell";
            Documentation = "https://github.com/Aylur/ags";
          };
          Service = {
            Environment = [
              # NOTE: this or use `dbus-update-activation-environment --systemd <env_var_name>`
              "TIMEWARRIORDB=${hmConfig.home.sessionVariables.TIMEWARRIORDB}"
            ];
            PassEnvironment = [ "HYPRLAND_INSTANCE_SIGNATURE" ];
            ExecStart = "${agsFinal}/bin/ags --bus-name $XDG_SESSION_DESKTOP";
            Restart = "on-failure";
            KillMode = "mixed";
          };
        });

      # HACK: delete temp files used by AGS osd
      systemd.user.services.progress-osd = lib._custom.mkWaylandService {
        Service = {
          Type = "oneshot";
          PassEnvironment = [ "UID" ];
          ExecStart =
            "${pkgs.bash}/bin/bash -c 'if [ -p /run/user/$UID/progress_osd ]; then ${pkgs.coreutils}/bin/rm /run/user/$UID/progress_osd; fi && ${pkgs.coreutils}/bin/mkfifo /run/user/$UID/progress_osd'";
        };
      };
      systemd.user.services.progress-icon-osd = lib._custom.mkWaylandService {
        Service = {
          Type = "oneshot";
          PassEnvironment = [ "UID" ];
          ExecStart =
            "${pkgs.bash}/bin/bash -c 'if [ -p /run/user/$UID/progress_icon_osd ]; then ${pkgs.coreutils}/bin/rm /run/user/$UID/progress_icon_osd; fi && ${pkgs.coreutils}/bin/mkfifo /run/user/$UID/progress_icon_osd'";
        };
      };
    };
  };
}
