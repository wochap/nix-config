{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.uwsm;

  # Helper function to create desktop entry files for UWSM-managed compositors
  mk_uwsm_desktop_entry = opts:
    (pkgs.writeTextFile {
      name = "${opts.name}-uwsm";
      text = ''
        [Desktop Entry]
        Name=${opts.prettyName} (UWSM)
        Comment=${opts.comment}
        Exec=${
          lib.getExe cfg.package
        } start -S -F -N ${opts.prettyName} -D ${opts.xdgCurrentDesktop} -- ${opts.binPath} > /dev/null
        Type=Application
      '';
      destination = "/share/wayland-sessions/${opts.name}-uwsm.desktop";
      derivationArgs = { passthru.providedSessions = [ "${opts.name}-uwsm" ]; };
    });
in {
  options._custom.desktop.uwsm = {
    enable = lib.mkEnableOption { };
    package = lib.mkPackageOption pkgs "uwsm" { };
    # slightly similar to https://search.nixos.org/options?channel=25.05&show=programs.uwsm.waylandCompositors&from=0&size=50&sort=relevance&type=packages&query=uwsm
    waylandCompositors = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ ... }: {
        options = {
          prettyName = lib.mkOption { type = lib.types.str; };
          comment = lib.mkOption { type = lib.types.str; };
          binPath = lib.mkOption { type = lib.types.path; };
          xdgCurrentDesktop = lib.mkOption { type = lib.types.str; };
        };
      }));
      example = lib.literalExpression ''
        hyprland = {
          prettyName = "Hyprland";
          comment = "Hyprland compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/Hyprland";
          xdgCurrentDesktop = "Hyprland";
        };
      '';
    };
  };

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

    services.displayManager.sessionPackages = lib.mapAttrsToList (name: value:
      mk_uwsm_desktop_entry {
        inherit name;
        inherit (value) prettyName comment binPath xdgCurrentDesktop;
      }) cfg.waylandCompositors;

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
