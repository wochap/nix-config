{ config, lib, pkgs, ... }:

let
  cfg = config._custom.de.sfwbar;
  inherit (config._custom.globals) configDirectory;
in {
  options._custom.de.sfwbar.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ sfwbar ];

      xdg.configFile."sfwbar/sfwbar.config".source =
        lib._custom.relativeSymlink configDirectory ./dotfiles/sfwbar.config;

      # systemd.user.services.sfwbar = {
      #   Unit = {
      #     Description = "S* Floating Window Bar";
      #     Documentation = "https://github.com/LBCrion/sfwbar";
      #     PartOf = [ "wayland-session.target" ];
      #     After = [ "wayland-session.target" ];
      #   };
      #
      #   Service = {
      #     PassEnvironment = "PATH";
      #     ExecStart = "${pkgs.sfwbar}/bin/waybar";
      #     Restart = "on-failure";
      #     KillMode = "mixed";
      #   };
      #
      #   Install.WantedBy = [ "wayland-session.target" ];
      # };
    };
  };
}

