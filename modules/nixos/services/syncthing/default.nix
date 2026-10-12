{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.syncthing;
  inherit (config._custom.globals) userName homeDirectory;
  inherit (pkgs._custom) wochap-ssc;
  proxy = config._custom.services.web-gate.proxies.syncthing;
  # GUI login shared by every host; the password is plaintext, syncthing hashes it
  syncthingUserName = "wochap";
  guiPasswordFile = config.sops.secrets.local-syncthing-password.path;
  hasDomain = cfg.tailnetDomain != null;
in
{
  options._custom.services.syncthing = {
    enable = lib.mkEnableOption { };
    # headless host: system service (no lingering, no web-gate), GUI and sync
    # port only reachable over the tailnet
    tailnetOnly = lib.mkEnableOption { };
    # tailnetOnly: Caddy vhost with a Let's Encrypt cert from the Cloudflare
    # DNS-01 challenge (no public record or open port); tailnet clients resolve
    # it to the tailnet IP (e.g. a headscale `dns.extra_records` entry)
    tailnetDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "syncthing.vps.example.com";
    };
    cloudflareTokenSecret = {
      sopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "SOPS file with a Cloudflare API token (Zone DNS Edit, Zone Read) for the DNS-01 challenge.";
      };
      sopsKey = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "server-cloudflare-dns-api-token";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        sops.secrets.local-syncthing-password = {
          sopsFile = ../../../../secrets-sops/local.yaml;
          owner = userName;
        };
      }

      (lib.mkIf (!cfg.tailnetOnly) {
        # https://syncthing.wochap.local
        _custom.services.web-gate.proxies.syncthing = {
          enable = true;
          subdomain = "syncthing";
          publicPort = 8383;
          backendPort = 8384;
          # keep syncthing always running, nginx hits backendPort directly
          lazy = false;
        };

        _custom.hm = {
          services.syncthing = {
            enable = true;
            guiAddress = "${wochap-ssc.meta.address}:${toString proxy.backendPort}";
            # nginx forwards Host as syncthing.wochap.local, syncthing rejects
            # non-localhost hosts unless this is set
            settings.gui.insecureSkipHostcheck = true;
            guiCredentials = {
              username = syncthingUserName;
              passwordFile = guiPasswordFile;
            };
            # settings != {} triggers syncthing-init, keep folders/devices added via GUI
            overrideDevices = false;
            overrideFolders = false;
            # openDefaultPorts = true;
            # relay.enable = false;
            # settings.options = {
            #   urAccepted = -1;
            #   globalDiscoveryEnabled = false;
            # };
          };
          # syncthing-init polls the GUI port once a second for ~17 minutes
          # before giving up; switch-to-configuration waits on it. Cap it.
          systemd.user.services.syncthing-init.Service.TimeoutStartSec = "60s";
        };
      })

      (lib.mkIf cfg.tailnetOnly {
        # http://<tailnet ip>:8384, or https://<tailnetDomain> when set
        services.syncthing = {
          enable = true;
          user = userName;
          group = "users";
          # base for new folders (~/Sync), keeps synced files in the user's home
          dataDir = homeDirectory;
          configDir = "${homeDirectory}/.local/state/syncthing";
          # firewall limits it to tailscale0; behind Caddy it stays on loopback
          guiAddress = if hasDomain then "127.0.0.1:8384" else "0.0.0.0:8384";
          # settings != {} triggers syncthing-init, keep folders/devices added via GUI
          overrideDevices = false;
          overrideFolders = false;
          settings.gui.user = syncthingUserName;
          # Caddy forwards Host as <tailnetDomain>, syncthing rejects
          # non-localhost hosts unless this is set
          settings.gui.insecureSkipHostcheck = hasDomain;
          inherit guiPasswordFile;
          settings.options = {
            urAccepted = -1;
            # no LAN on the VPS
            localAnnounceEnabled = false;
            # relays would let peers reach it around the tailnet-only firewall
            relaysEnabled = false;
            # don't publish the public IP to (or query) discovery servers; peers
            # set its tailnet address explicitly
            globalAnnounceEnabled = false;
            globalDiscoveryEnabled = false;
            # no UPnP/NAT-PMP on the VPS
            natEnabled = false;
          };
        };
        systemd.services.syncthing-init.serviceConfig.TimeoutStartSec = "60s";

        networking.firewall.interfaces.tailscale0 = {
          allowedTCPPorts = [ 22000 ] ++ lib.optional (!hasDomain) 8384 ++ lib.optional hasDomain 443;
          allowedUDPPorts = [ 22000 ];
        };
      })

      (lib.mkIf (cfg.tailnetOnly && hasDomain) {
        assertions = [
          {
            assertion = cfg.cloudflareTokenSecret.sopsFile != null;
            message = "_custom.services.syncthing.tailnetDomain needs cloudflareTokenSecret.sopsFile";
          }
        ];

        sops.secrets.${cfg.cloudflareTokenSecret.sopsKey}.sopsFile = cfg.cloudflareTokenSecret.sopsFile;

        security.acme = {
          acceptTerms = true;
          certs.${cfg.tailnetDomain} = {
            dnsProvider = "cloudflare";
            # the local resolver may answer from cache
            dnsResolver = "1.1.1.1:53";
            group = config.services.caddy.group;
            reloadServices = [ "caddy.service" ];
            credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
              config.sops.secrets.${cfg.cloudflareTokenSecret.sopsKey}.path;
          };
        };

        # Caddy may also serve other sites on the public 443 (e.g. headscale):
        # drop anything that does not come over the tailnet
        services.caddy = {
          enable = true;
          virtualHosts.${cfg.tailnetDomain} = {
            useACMEHost = cfg.tailnetDomain;
            extraConfig = ''
              @outside not remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
              abort @outside
              reverse_proxy 127.0.0.1:8384
            '';
          };
        };
      })
    ]
  );
}
