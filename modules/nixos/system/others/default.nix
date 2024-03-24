{ lib, ... }:

{
  config = {
    # minimum amount of swapping without disabling it entirely
    boot.kernel.sysctl."vm.swappiness" = lib.mkDefault 1;

    # Links those paths from derivations to /run/current-system/sw
    environment.pathsToLink = [ "/share" "/libexec" ];

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

    console = {
      earlySetup = true;
      keyMap = lib.mkDefault "us";
    };

    hardware.opengl.enable = true;

    # documentation.man.generateCaches = true;
    documentation.dev.enable = true;
  };
}

