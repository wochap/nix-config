{ config, lib, inputs, pkgs, system, ... }:

let
  cfg = config._custom.de.ags;
  inherit (config._custom.globals) configDirectory;
  agsFinal = inputs.ags.packages.${system}.default;
  capslock =
    pkgs.writeScriptBin "capslock" (builtins.readFile ./scripts/capslock.sh);
in {
  options._custom.de.ags = {
    enable = lib.mkEnableOption { };
    systemdEnable = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    security.pam.services.ags = { };

    _custom.hm = {
      imports = [ inputs.ags.homeManagerModules.default ];

      home.packages = [ capslock ];

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
    };
  };
}
