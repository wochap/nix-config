{ config, lib, inputs, pkgs, system, ... }:

let
  cfg = config._custom.desktop.ags;
  inherit (config._custom.globals) configDirectory;
  agsFinal = inputs.ags.packages.${system}.default;
  capslock =
    pkgs.writeScriptBin "capslock" (builtins.readFile ./scripts/capslock.sh);
  progress-osd = pkgs.writeScriptBin "progress-osd"
    (builtins.readFile ./scripts/progress-osd.sh);
in {
  options._custom.desktop.ags = {
    enable = lib.mkEnableOption { };
    systemdEnable = lib.mkEnableOption { };
    mainOutputName = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    security.pam.services.ags = { };

    _custom.hm = {
      imports = [ inputs.ags.homeManagerModules.default ];

      home.packages = [ capslock progress-osd ];
      home.sessionVariables."MAIN_OUTPUT_NAME" = cfg.mainOutputName;

      programs.ags = {
        enable = true;
        package = agsFinal;
      };

      xdg.configFile."ags".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles;

      systemd.user.services.ags = lib.mkIf cfg.systemdEnable
        (lib._custom.mkWaylandService {
          Unit = {
            Description = "A customizable and extensible shell";
            Documentation = "https://github.com/Aylur/ags";
          };
          Service = {
            PassEnvironment = [
              "PATH"
              "XDG_SESSION_DESKTOP"
              "MAIN_OUTPUT_NAME"
              "HYPRLAND_INSTANCE_SIGNATURE"
            ];
            ExecStart = "${agsFinal}/bin/ags";
            Restart = "on-failure";
            KillMode = "mixed";
          };
        });

      systemd.user.services.progress-osd = lib._custom.mkWaylandService {
        Service = {
          Type = "oneshot";
          PassEnvironment = [ "PATH" "UID" ];
          ExecStart =
            "${pkgs.bash}/bin/bash -c 'if [ -p /run/user/$UID/progress_osd ]; then ${pkgs.coreutils}/bin/rm /run/user/$UID/progress_osd; fi && ${pkgs.coreutils}/bin/mkfifo /run/user/$UID/progress_osd'";
        };
      };
      systemd.user.services.progress-icon-osd = lib._custom.mkWaylandService {
        Service = {
          Type = "oneshot";
          PassEnvironment = [ "PATH" "UID" ];
          ExecStart =
            "${pkgs.bash}/bin/bash -c 'if [ -p /run/user/$UID/progress_icon_osd ]; then ${pkgs.coreutils}/bin/rm /run/user/$UID/progress_icon_osd; fi && ${pkgs.coreutils}/bin/mkfifo /run/user/$UID/progress_icon_osd'";
        };
      };
    };
  };
}
