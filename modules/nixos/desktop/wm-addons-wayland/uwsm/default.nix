{ config, pkgs, lib, ... }:

let cfg = config._custom.desktop.uwsm;
in {
  options._custom.desktop.uwsm.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    # make wayland compositors great again
    # better resource management
    programs.uwsm.enable = true;
    programs.uwsm.waylandCompositors = { };

    environment.etc."greetd/environments".text = lib.mkAfter ''
      uwsm
    '';

    # source: https://github.com/m-bdf/nixos/blob/4c2c9c7c389c65ae15588b77885f9adbae7c1bdc/config/utils.nix#L29
    xdg.terminal-exec.package = pkgs.writeShellScriptBin "xdg-terminal-exec" ''
      uwsm-app -T -- "''${@-$SHELL}"
    '';

    _custom.hm = {
      home.sessionVariables.UWSM_USE_SESSION_SLICE = "true";
      home.sessionVariables.UWSM_APP_UNIT_TYPE = "service";

      xdg.configFile."uwsm/env".text = ''
        export XCURSOR_THEME=$XCURSOR_THEME
        export XCURSOR_SIZE=$XCURSOR_SIZE
        export HOME=$HOME
        export QT_QPA_PLATFORMTHEME=$QT_QPA_PLATFORMTHEME
      '';

      # HACK: start app-daemon
      systemd.user.services.start-uwsm-app-daemon =
        lib._custom.mkWaylandService {
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.uwsm}/bin/uwsm-app -- zsh -c exit";
          };
        };
    };
  };
}
