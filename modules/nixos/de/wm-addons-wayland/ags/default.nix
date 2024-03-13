{ config, lib, inputs, pkgs, system, ... }:

let
  cfg = config._custom.de.ags;
  inherit (config._custom.globals) configDirectory;
  agsFinal = inputs.ags.packages.${system}.default;
  capslock =
    pkgs.writeScriptBin "capslock" (builtins.readFile ./scripts/capslock.sh);
  progress-osd = pkgs.writeScriptBin "progress-osd"
    (builtins.readFile ./scripts/progress-osd.sh);
in {
  options._custom.de.ags = {
    enable = lib.mkEnableOption { };
    systemdEnable = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    security.pam.services.ags = { };

    _custom.hm = {
      imports = [ inputs.ags.homeManagerModules.default ];

      home.packages = [ capslock progress-osd ];

      programs.ags = {
        enable = true;
        package = agsFinal;
      };

      xdg.configFile."ags".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles;

      systemd.user.services.ags = lib.mkIf cfg.systemdEnable {
        Unit = {
          Description = "A customizable and extensible shell";
          Documentation = "https://github.com/Aylur/ags";
          PartOf = [ "wayland-session.target" ];
          After = [ "wayland-session.target" ];
        };

        Service = {
          PassEnvironment = "PATH";
          ExecStart = "${agsFinal}/bin/ags";
          Restart = "on-failure";
          KillMode = "mixed";
        };

        Install.WantedBy = [ "wayland-session.target" ];
      };

      systemd.user.services.progress-osd = lib._custom.mkWaylandService {
        Unit.Description = "OSD made with ags";
        Unit.Documentation = "https://github.com/Aylur/ags";
        Service = {
          Type = "oneshot";
          PassEnvironment = [ "PATH" "UID" ];
          ExecStart =
            "${pkgs.bash}/bin/bash -c 'if [ -p /run/user/$UID/progress_osd ]; then rm /run/user/$UID/progress_osd; fi && ${pkgs.coreutils}/bin/mkfifo /run/user/$UID/progress_osd'";
        };
      };
    };
  };
}
