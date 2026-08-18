{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config._custom.system.others;
  inherit (config._custom.globals) isSandbox;
in
{
  options._custom.system.others.enable = lib.mkEnableOption { };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Links those paths from derivations to /run/current-system/sw
      environment.pathsToLink = [
        "/share"
        # binaries
        "/libexec"
        # C libs
        "/lib"
      ];

      # Shell integration for VTE terminals
      # Required for some gtk apps
      programs.bash.vteIntegration = lib.mkDefault true;
      programs.zsh.vteIntegration = lib.mkDefault true;

      systemd.settings.Manager.DefaultTimeoutStopSec = "30s";
      systemd.coredump.settings.Coredump = {
        MaxUse = "500M";
        MaxRetentionSec = "7d";
      };

      services.journald.extraConfig = ''
        SystemMaxUse=1G
        MaxRetentionSec=7d
      '';

      # Enables to run hardware-accelerated apps
      hardware.graphics.enable = true;
    })

    (lib.mkIf (cfg.enable && (!isSandbox)) {
      # minimum amount of swapping without disabling it entirely
      boot.kernel.sysctl."vm.swappiness" = lib.mkDefault 1;

      # security camera for your system. Doesn't prevent anything. Records everything.
      security.auditd.enable = true;

      # kill processes before OOM kernel panic
      services.earlyoom.enable = true;

      # rotate and compress system logs
      services.logrotate.enable = true;

      services.xserver = {
        enable = true;
        exportConfiguration = true;
      };

      # run sysctl after the graphical session has started
      # otherwise, rules in sysctl files won't be applied
      systemd.services.custom-sysctl = {
        description = "Apply sysctl settings";
        wantedBy = [ "graphical.target" ];
        after = [ "graphical.target" ];
        partOf = [ "graphical.target" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.procps}/bin/sysctl --system";
        };
      };

      systemd.user.extraConfig = ''
        # update PATH for user systemd services
        DefaultEnvironment="PATH=/run/wrappers/bin:/etc/profiles/per-user/%u/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"

        DefaultTimeoutStopSec=30s
      '';
    })
  ];
}
