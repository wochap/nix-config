{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.nix-cache;
  inherit (pkgs._custom) wochap-ssc;
  gate = config._custom.services.web-gate;
  proxy = config._custom.services.web-proxies.nix-cache;

  sopsSecretOptions = description: defaultKey: {
    sopsFile = lib.mkOption {
      type = lib.types.path;
      description = "SOPS file containing the ${description}.";
    };
    sopsKey = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = defaultKey;
      description = "Key containing the ${description} in the SOPS file.";
    };
  };
in
{
  options._custom.services.nix-cache = {
    server = {
      enable = lib.mkEnableOption "serving this host's Nix store as a binary cache on the LAN (harmonia)";
      port = lib.mkOption {
        type = lib.types.port;
        default = 21500;
        description = "web-proxies public port; harmonia listens on port + 1.";
      };
      signingKey = sopsSecretOptions "harmonia signing key (nix-store --generate-binary-cache-key)" "nix-cache-signing-key";
      htpasswd = sopsSecretOptions "htpasswd file that guards the cache" "nix-cache-htpasswd";
    };

    client = {
      caches = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              url = lib.mkOption {
                type = lib.types.str;
                example = "https://cache.example.com";
              };
              publicKey = lib.mkOption {
                type = lib.types.str;
                example = "cache.example.com-1:AAAA...";
              };
              priority = lib.mkOption {
                type = lib.types.int;
                default = 30;
                description = "Lower is preferred; cache.nixos.org uses 40.";
              };
            };
          }
        );
        default = { };
        description = "LAN binary caches to substitute from, tried before the public caches.";
      };
      netrc = sopsSecretOptions "netrc file with credentials for the caches" "nix-cache-netrc";
      connectTimeout = lib.mkOption {
        type = lib.types.ints.positive;
        default = 3;
        description = "Seconds before an unreachable cache is skipped for the rest of the run.";
      };
    };

    remoteBuilds = {
      serve = {
        enable = lib.mkEnableOption "accepting remote builds over SSH (nix-ssh user)";
        authorizedKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Public SSH keys of the root users that may build here.";
        };
      };
      machines = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                hostName = lib.mkOption {
                  type = lib.types.str;
                  default = name;
                };
                hostKey = lib.mkOption {
                  type = lib.types.str;
                  example = "ssh-ed25519 AAAA...";
                  description = "The builder's SSH host public key (/etc/ssh/ssh_host_ed25519_key.pub).";
                };
                systems = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ pkgs.stdenv.hostPlatform.system ];
                };
                maxJobs = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 8;
                };
                speedFactor = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 2;
                  description = "Relative speed; the local host counts as 1.";
                };
                supportedFeatures = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [
                    "benchmark"
                    "big-parallel"
                    "kvm"
                    "nixos-test"
                  ];
                };
              };
            }
          )
        );
        default = { };
        description = "Remote builders this host offloads builds to over ssh-ng.";
      };
      sshKey = sopsSecretOptions "root SSH private key used to reach the remote builders" "nix-remote-build-ssh-key";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.server.enable {
      sops.secrets.${cfg.server.signingKey.sopsKey}.sopsFile = cfg.server.signingKey.sopsFile;
      sops.secrets.${cfg.server.htpasswd.sopsKey} = {
        inherit (cfg.server.htpasswd) sopsFile;
        owner = config.services.nginx.user;
      };

      services.harmonia.cache = {
        enable = true;
        signKeyPaths = [ config.sops.secrets.${cfg.server.signingKey.sopsKey}.path ];
        settings.bind = "${wochap-ssc.meta.address}:${toString proxy.backendPort}";
      };

      # Served at https://cache.<web-gate.domain> on the LAN. Plain Basic Auth,
      # because Nix sends netrc credentials but cannot follow the gate cookie.
      _custom.services.web-proxies.nix-cache = {
        enable = true;
        subdomain = "cache";
        serviceName = "harmonia";
        publicPort = cfg.server.port;
        expose = {
          enable = true;
          basicAuthFile = config.sops.secrets.${cfg.server.htpasswd.sopsKey}.path;
        };
      };
    })

    (lib.mkIf (cfg.client.caches != { }) {
      sops.secrets.${cfg.client.netrc.sopsKey}.sopsFile = cfg.client.netrc.sopsFile;

      nix.settings = {
        substituters = lib.mapAttrsToList (
          _: c: "${c.url}?priority=${toString c.priority}"
        ) cfg.client.caches;
        trusted-public-keys = lib.mapAttrsToList (_: c: c.publicKey) cfg.client.caches;
        netrc-file = config.sops.secrets.${cfg.client.netrc.sopsKey}.path;
        connect-timeout = cfg.client.connectTimeout;
        # Build locally when a cache disappears mid-download.
        fallback = true;
      };
    })

    (lib.mkIf cfg.remoteBuilds.serve.enable {
      nix.sshServe = {
        enable = true;
        protocol = "ssh-ng";
        write = true;
        # Clients upload unsigned build inputs.
        trusted = true;
        keys = cfg.remoteBuilds.serve.authorizedKeys;
      };
    })

    (lib.mkIf (cfg.remoteBuilds.machines != { }) {
      sops.secrets.${cfg.remoteBuilds.sshKey.sopsKey}.sopsFile = cfg.remoteBuilds.sshKey.sopsFile;

      nix = {
        distributedBuilds = true;
        settings.builders-use-substitutes = true;
        buildMachines = lib.mapAttrsToList (_: m: {
          inherit (m)
            hostName
            systems
            maxJobs
            speedFactor
            supportedFeatures
            ;
          protocol = "ssh-ng";
          sshUser = "nix-ssh";
          sshKey = config.sops.secrets.${cfg.remoteBuilds.sshKey.sopsKey}.path;
        }) cfg.remoteBuilds.machines;
      };

      # Pins the builder's host key in /etc/ssh/ssh_known_hosts.
      programs.ssh.knownHosts = lib.mapAttrs' (
        _: m: lib.nameValuePair m.hostName { publicKey = m.hostKey; }
      ) cfg.remoteBuilds.machines;

      # An absent builder (laptop away from home) costs a few seconds, then
      # the build runs locally.
      programs.ssh.extraConfig = lib.concatMapStrings (m: ''
        Host ${m.hostName}
          ConnectTimeout 3
      '') (lib.attrValues cfg.remoteBuilds.machines);
    })
  ];
}
