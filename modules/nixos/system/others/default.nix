{ lib, ... }:

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
  };
}

