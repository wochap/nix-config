{ lib, pkgs, ... }:

{
  config = {
    # minimum amount of swapping without disabling it entirely
    boot.kernel.sysctl."vm.swappiness" = lib.mkDefault 1;

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

    services.xserver = {
      enable = true;
      exportConfiguration = true;
    };

    systemd.extraConfig = ''
      DefaultTimeoutStopSec=15s
    '';

    hardware.graphics.enable = true;

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
  };
}

