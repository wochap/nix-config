{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config._custom.sandbox;
  inherit (config._custom.globals) userName;
  sandboxName = "sandbox";
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
    networking = {
      nat = {
        enable = true;
        # Tell NAT to listen to all systemd-nspawn virtual interfaces
        internalInterfaces = [ "ve-+" ];

        # IMPORTANT: Change this to your actual host internet interface
        # (Check using `ip a` or `ip link`, e.g., "enp4s0" or "wlp3s0")
        externalInterface = cfg.internetInterface;
      };

      firewall = {
        trustedInterfaces = [ "ve-+" ];
        # prevent sandbox from reaching local network devices
        extraCommands = ''
          # Create a custom chain for the sandbox
          iptables -N SANDBOX-ISOLATION || true

          # Route all forwarding traffic originating from the sandbox to this chain
          # (Using index 1 ensures this is evaluated before NixOS's default NAT ACCEPT rules)
          iptables -I FORWARD 1 -s 192.168.100.11/32 -j SANDBOX-ISOLATION

          # 1. ALLOW: The sandbox must be able to talk to the host to use it as a gateway
          iptables -A SANDBOX-ISOLATION -d 192.168.100.10/32 -j ACCEPT

          # 2. DROP: Block the sandbox from reaching anything else on your physical LAN
          iptables -A SANDBOX-ISOLATION -d 10.0.0.0/8 -j DROP
          iptables -A SANDBOX-ISOLATION -d 172.16.0.0/12 -j DROP
          iptables -A SANDBOX-ISOLATION -d 192.168.0.0/16 -j DROP

          # 3. RETURN: Anything not dropped (e.g., public internet IPs) returns to normal routing
          iptables -A SANDBOX-ISOLATION -j RETURN
        '';

        extraStopCommands = ''
          # Safely clean up our custom rules when the firewall restarts
          iptables -D FORWARD -s 192.168.100.11/32 -j SANDBOX-ISOLATION || true
          iptables -F SANDBOX-ISOLATION || true
          iptables -X SANDBOX-ISOLATION || true
        '';
      };
    };

    # Stop these annoyings polkit popups when typing sandbox name
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id.indexOf("org.freedesktop.machine1.") === 0 &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';

    # Create shared directory
    systemd.tmpfiles.rules = [
      "d /home/${userName}/Sandboxes 0755 ${userName} users -"
      "d /home/${userName}/Sandboxes/${userName} 0755 ${userName} users -"
    ];

    # Proxy dbus
    environment.systemPackages = [ pkgs.xdg-dbus-proxy ];
    systemd.user.services.sandbox-dbus-proxy = {
      description = "Filtered D-Bus proxy for sandbox";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "simple";
        # %t resolves to the user's runtime dir (e.g., /run/user/1000)
        # --filter drops all access by default
        # --talk allows sending messages to the notification daemon
        ExecStart = "${pkgs.xdg-dbus-proxy}/bin/xdg-dbus-proxy unix:path=%t/bus %t/sandbox-bus --filter --talk=org.freedesktop.Notifications --call=org.freedesktop.portal.Desktop=org.freedesktop.portal.FileChooser --call=org.freedesktop.portal.Desktop=org.freedesktop.portal.OpenURI --call=org.freedesktop.portal.Desktop=org.freedesktop.portal.Settings";
        Restart = "on-failure";
      };
    };

    containers.${sandboxName} = {
      # Start manually using `sudo nixos-container start <container_name>`
      # Enter manually using `sudo machinectl shell <user_name>@<container_name>`
      autoStart = false;
      # NOTE: More security but breaks opening GUI on host from sandbox
      # extraFlags = [ "-U" ]; # Tells systemd-nspawn to use user namespaces
      privateNetwork = true;
      hostAddress = "192.168.100.10";
      localAddress = "192.168.100.11";
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
        "wayland" = {
          hostPath = "/run/user/${toString cfg.hostUserUid}/wayland-1";
          mountPoint = "/mnt/host-run/wayland-1";
          isReadOnly = false;
        };
        # Native PipeWire Audio
        "pipewire" = {
          hostPath = "/run/user/${toString cfg.hostUserUid}/pipewire-0";
          mountPoint = "/mnt/host-run/pipewire-0";
          isReadOnly = false;
        };
        # Legacy PulseAudio Audio (for Electron apps)
        "pulseaudio" = {
          hostPath = "/run/user/${toString cfg.hostUserUid}/pulse/native";
          mountPoint = "/mnt/host-run/pulse/native";
          isReadOnly = false;
        };
        # Notifications & Desktop Portals (Safe Proxy)
        "dbus-proxy" = {
          hostPath = "/run/user/${toString cfg.hostUserUid}/sandbox-bus";
          mountPoint = "/mnt/host-run/bus";
          isReadOnly = false;
        };
        # Theme, desktop settings
        "dconf-db" = {
          hostPath = "/home/${userName}/.config/dconf/user";
          mountPoint = "/home/${userName}/.config/dconf/user";
          isReadOnly = true;
        };
      };
      specialArgs = {
        inherit inputs;
        inherit lib;
      };

      config =
        { ... }:
        {
          imports = [
            ../archetypes
            ../nixos
            ../shared
            ./host.nix
          ];

          config = {
            # force sandbox to use same host pkgs
            nixpkgs.pkgs = pkgs;

            networking.hostName = sandboxName;
            networking.useHostResolvConf = lib.mkForce false;

            environment.sessionVariables = {
              # used by others apps to show indicator that we are in sandbox
              IN_SANDBOX = "true";
              # TODO: maybe use cage?
              WAYLAND_DISPLAY = "/mnt/host-run/wayland-1";
              PIPEWIRE_RUNTIME_DIR = "/mnt/host-run";
              PULSE_SERVER = "unix:/mnt/host-run/pulse/native";
              # TODO: set pinentry-tty?
              DBUS_SESSION_BUS_ADDRESS = "unix:path=/mnt/host-run/bus";
            };

            _custom.sandbox.userName = userName;

            _custom.user = {
              linger = true; # start user systemd services
              uid = cfg.hostUserUid;
              extraGroups = [
                "render"
              ];
            };

            _custom.programs.foot.settings.main = config._custom.programs.foot.settings.main;
          };
        };
    };
  };
}
