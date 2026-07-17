{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.sandbox;
  inherit (config._custom.globals) userName;
in
{
  options._custom.sandbox = {
    enable = lib.mkEnableOption { };
    internetInterface = lib.mkOption {
      type = lib.types.str;
      default = "wlan0";
      description = "host internet interface";
    };
    hostUserUid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "host user uid";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.nat = {
      enable = true;
      # Tell NAT to listen to all systemd-nspawn virtual interfaces
      internalInterfaces = [ "ve-+" ];

      # IMPORTANT: Change this to your actual host internet interface
      # (Check using `ip a` or `ip link`, e.g., "enp4s0" or "wlp3s0")
      externalInterface = cfg.internetInterface;
    };

    # Create shared directory
    systemd.tmpfiles.rules = [
      "d /home/${userName}/Sandboxes 0755 ${userName} users -"
      "d /home/${userName}/Sandboxes/${userName} 0755 ${userName} users -"
    ];

    containers.${userName} = {
      # Start manually using `sudo nixos-container start <name>`
      autoStart = false;
      privateNetwork = true;
      hostAddress = "10.0.0.1";
      localAddress = "10.0.0.2";
      bindMounts = {
        "shared" = {
          hostPath = "/home/${userName}/Sandboxes/${userName}";
          mountPoint = "/home/${userName}/Shared";
          isReadOnly = false;
        };
        "dri" = {
          hostPath = "/dev/dri";
          mountPoint = "/dev/dri";
          isReadOnly = false;
        };
        # TODO: cherry pick just what we need here
        "runtime-dir" = {
          hostPath = "/run/user/${toString cfg.hostUserUid}";
          mountPoint = "/mnt/host-run";
          isReadOnly = false;
        };
      };

      config = { config, pkgs, ... }: {
        system.stateVersion = "23.11";

        systemd.services."container-getty@1" = {
          enable = true;
        };

        # Enable DNS resolution inside the sandbox
        networking.nameservers = [
          "8.8.8.8"
          "1.1.1.1"
        ];
        networking.useHostResolvConf = lib.mkForce false;

        users.users.${userName} = {
          isNormalUser = true;
          uid = cfg.hostUserUid;
          extraGroups = [
            "video"
            "audio"
            "wheel"
            "render"
          ];
          initialPassword = "sandbox";
        };

        hardware.graphics.enable = true;

        environment.variables = {
          WAYLAND_DISPLAY = "/mnt/host-run/wayland-1";
          PIPEWIRE_RUNTIME_DIR = "/mnt/host-run";
          QT_QPA_PLATFORM = "wayland";
          GDK_BACKEND = "wayland";
          MOZ_ENABLE_WAYLAND = "1";
        };

        environment.systemPackages = with pkgs; [
          firefox
          foot
          python3
        ];
      };
    };
  };
}
