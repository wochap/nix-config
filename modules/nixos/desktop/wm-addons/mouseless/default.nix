{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.desktop.mouseless;
  tomlFormat = pkgs.formats.toml { };

  woints = inputs.woints.packages.${pkgs.stdenv.hostPlatform.system}.default;
  woints-hyprland = inputs.woints.packages.${pkgs.stdenv.hostPlatform.system}.hyprland-module;
in
{
  options._custom.desktop.mouseless = {
    enable = lib.mkEnableOption { };
    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          keys = {
            mode = "explicit";
            alphabet = "arstneiogm";
          };
        }
      '';
      description = ''
        Configuration for woints written to ~/.config/woints/config.toml.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ woints ];

    _custom.desktop.a11y.enable = lib.mkDefault true;

    _custom.hm = {
      # Key capture submap for Hyprland, loaded by `require("woints")` in binds.lua
      xdg.configFile."hypr/woints.lua".source = "${woints-hyprland}/share/hypr/woints.lua";

      xdg.configFile."woints/config.toml" = lib.mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "woints-config.toml" cfg.settings;
      };

      systemd.user.services.wointsd = lib._custom.mkWaylandService {
        Unit = {
          Description = "woints hint daemon";
          After = [
            "graphical-session.target"
            "a11y-enable.service"
          ];
          Wants = [ "a11y-enable.service" ];
        };
        Service = {
          ExecStart = "${woints}/bin/wointsd";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };
    };
  };
}
