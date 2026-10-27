{ config, lib, ... }:

let
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
in
{
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
  ];

  config = {
    _custom.globals.userName = userName;
    _custom.globals.homeDirectory = "/home/${userName}";
    _custom.globals.configDirectory = configDirectory;
    _custom.globals.preferDark = true;

    _custom.archetypes.server.enable = true;

    # cli
    # _custom.programs.core-utils-extra-linux.enable = true;
    _custom.programs.core-utils-linux.enable = true;
    _custom.programs.nix-direnv.enable = true;

    # gui
    # none

    # tui
    # none

    # cli
    _custom.programs.bat.enable = true;
    # _custom.programs.core-utils-extra.enable = true;
    _custom.programs.core-utils.enable = true;
    _custom.programs.dircolors.enable = true;
    _custom.programs.fzf.enable = true;
    _custom.programs.git.enable = true;
    _custom.programs.git.settings = {
      user = {
        email = "gvps@localhost";
        name = "gvps";
      };
    };
    _custom.programs.lazygit.enable = true;
    _custom.programs.lsd.enable = true;
    # _custom.programs.ptsh.enable = true;
    # _custom.programs.texlive.enable = true;
    _custom.programs.zk.enable = true;
    _custom.programs.zoxide.enable = true;
    _custom.programs.zsh.enable = true;
    _custom.programs.zsh.isDefault = false;

    # dev
    # none

    # gui
    # none

    # tui
    # _custom.programs.amfora.enable = true;
    _custom.programs.btop.enable = true;
    _custom.programs.less.enable = true;
    # _custom.programs.lynx.enable = true;
    _custom.programs.neovim.enable = true;
    # _custom.programs.newsboat.enable = true;
    # _custom.programs.presenterm.enable = true;
    # _custom.programs.taskwarrior.enable = true;
    _custom.programs.tmux.enable = true;
    # _custom.programs.tmux.enableSystemd = true;
    # _custom.programs.urlscan.enable = true;
    _custom.programs.yazi.enable = true;
    # _custom.programs.youtube.enable = true;
    # _custom.programs.zellij.enable = true;
    # _custom.programs.ai-agents.enable = true;

    _custom.system.user.password = "$y$j9T$GChzlCM7cdSrWM/gynZTB/$S6k/k6zVDWfl0HBBdJ0lRT1XfGKSQ8lIbtplYgQLgp2";

    # public network: plain DHCP, no NetworkManager, dev ports or mDNS
    _custom.desktop.networking.enableIPv6 = true;
    # resolved: tailscale adds MagicDNS (remote builders) on tailscale0
    _custom.desktop.networking.nameservers = [
      "9.9.9.9"
      "149.112.112.112"
    ];

    _custom.desktop.power-management.enable = false;

    # hs: Cloudflare A record, DNS only. tail: MagicDNS suffix, no public record
    _custom.services.headscale = {
      enable = true;
      domain = "hs.geanmar.com";
      baseDomain = "tail.geanmar.com";
      # gvps tailnet IP (`tailscale ip -4`), runs AdGuard Home
      nameservers = [ "100.64.0.4" ];
      # My devices reach each other freely. Each friend gets their own
      # headscale user (`headscale users create <name>`), listed in
      # group:friends as "<name>@", and reaches only the media apps on
      # gdesktop, tt here, and DNS (nameservers above).
      policy = {
        groups."group:friends" = [ ];
        hosts = {
          gdesktop = "100.64.0.2/32";
          glegion = "100.64.0.3/32";
          gvps = "100.64.0.4/32";
        };
        acls = [
          {
            action = "accept";
            src = [ "gean@" ];
            dst = [ "gean@:*" ];
          }
          {
            action = "accept";
            src = [ "group:friends" ];
            dst = [
              # web-gate: jellyfin, seerr, audiobookshelf, calibre-web
              "gdesktop:443"
              # glegion media server, once it exposes the same apps
              # "glegion:443"
              # Caddy: tt, but also syncthing (has a login) and status (none)
              "gvps:443"
              # AdGuard Home; without it friends' DNS breaks
              "gvps:53"
            ];
          }
        ];
      };
    };
    _custom.services.tailscale = {
      enable = true;
      loginServer = "https://hs.geanmar.com";
      sshOnlyTailnet = false;
      # once gvps joined the tailnet and ssh over it works (KVM console is the fallback)
      # sshOnlyTailnet = true;
    };
    _custom.services.adguardhome = {
      enable = true;
      # same tailnet IP as headscale.nameservers; resolved keeps 127.0.0.53
      bindHosts = [
        "100.64.0.4"
        "127.0.0.1"
      ];
      users = [
        {
          name = "gean";
          password = "$2y$10$GOC64JoPERX.iazSHXb.FOBDeql.WsTs9mE5j1AteJlQCOMWMwCxK";
        }
      ];
    };

    # 2 vCores: build on gdesktop/glegion and substitute from their stores
    # over the tailnet whenever they are online; locally otherwise. Each
    # needs this host's ssh-host.pub in its remoteBuilds.serve.authorizedKeys.
    _custom.services.nix-cache.remoteBuilds.machines = {
      "gdesktop.tail.geanmar.com" = {
        hostKey = lib.fileContents ../gdesktop/ssh-host.pub;
        maxJobs = 12;
        speedFactor = 4;
        substituter.enable = true;
      };
      "glegion.tail.geanmar.com" = {
        hostKey = lib.fileContents ../glegion/ssh-host.pub;
        maxJobs = 8;
        speedFactor = 3;
        substituter.enable = true;
        substituter.priority = 51;
      };
    };

    _custom.services.syncthing = {
      enable = true;
      tailnetOnly = true;
      # https://syncthing.gvps.geanmar.com, tailnet devices only
      tailnetDomain = "syncthing.gvps.geanmar.com";
      cloudflareTokenSecret.sopsFile = ../../secrets-sops/server.yaml;
    };

    # Always-online member that relays changes between gdesktop and glegion,
    # web app at https://tt.gvps.geanmar.com for tailnet devices only.
    # Certificate via Cloudflare DNS-01 (no public record); tailnet clients
    # resolve the name to the tailnet IP below.
    # Pair once: `tt-server peer invite` on gdesktop, then
    # `tt-server peer join <code> --name gvps` here
    _custom.services.tt = {
      enable = true;
      daemon.enable = false;
      notify = false;
      server.tailnetOnly = true;
      server.tailnetDomain = "tt.gvps.geanmar.com";
      server.cloudflareTokenSecret.sopsFile = ../../secrets-sops/server.yaml;
      server.peer.advertise = [ "gvps.tail.geanmar.com:8772" ];
    };
    # Always-online wobook peer that relays bookmarks between gdesktop and
    # glegion over the tailnet. Pair once: `wobook pair` on gdesktop, then
    # `wobook pair --join -` here (paste the payload within ~2 min)
    _custom.services.wobook = {
      enable = true;
      tailnetOnly = true;
      # shows up as apps/wobook on the gatus status page
      statusPush.enable = true;
      statusPush.tokenSecret.sopsFile = ../../secrets-sops/server.yaml;
    };

    _custom.services.bugsink = {
      enable = true;
      tailnetDomain = "bugsink.gvps.geanmar.com";
      secretKeySecret.sopsFile = ../../secrets-sops/server.yaml;
      cloudflareTokenSecret.sopsFile = ../../secrets-sops/server.yaml;
      admin = {
        passwordSecret.sopsFile = ../../secrets-sops/server.yaml;
        usernameSecret.sopsFile = ../../secrets-sops/server.yaml;
      };
    };

    # Status page at https://status.gvps.geanmar.com for tailnet devices only,
    # checks every service above plus the extra endpoints below
    _custom.services.gatus = {
      enable = true;
      tailnetDomain = "status.gvps.geanmar.com";
      cloudflareTokenSecret.sopsFile = ../../secrets-sops/server.yaml;
      endpoints = [
        {
          name = "gdesktop";
          group = "tailnet";
          url = "icmp://gdesktop.tail.geanmar.com";
          interval = "5m";
          conditions = [ "[CONNECTED] == true" ];
        }
        {
          name = "glegion";
          group = "tailnet";
          url = "icmp://glegion.tail.geanmar.com";
          interval = "5m";
          conditions = [ "[CONNECTED] == true" ];
        }
        {
          name = "bugsink";
          group = "services";
          url = "https://bugsink.gvps.geanmar.com/health/ready";
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];
    };

    services.headscale.settings.dns.extra_records = [
      {
        name = "bugsink.gvps.geanmar.com";
        type = "A";
        value = "100.64.0.4";
      }
      {
        name = "tt.gvps.geanmar.com";
        type = "A";
        value = "100.64.0.4";
      }
      {
        name = "syncthing.gvps.geanmar.com";
        type = "A";
        value = "100.64.0.4";
      }
      {
        name = "status.gvps.geanmar.com";
        type = "A";
        value = "100.64.0.4";
      }
    ]
    # gdesktop's web-gate.tailnet vhosts; 100.64.0.2 is its tailnet IP, which
    # changes only if gdesktop registers as a new node (e.g. reinstall).
    ++
      map
        (name: {
          name = "${name}.gdesktop.geanmar.com";
          type = "A";
          value = "100.64.0.2";
        })
        [
          "jellyfin"
          "seerr"
          "audiobookshelf"
          "calibre-web"
        ];
    # glegion's, once it serves media with web-gate.tailnet.enable;
    # 100.64.0.3 is its tailnet IP.
    # ++ map
    #   (name: {
    #     name = "${name}.glegion.geanmar.com";
    #     type = "A";
    #     value = "100.64.0.3";
    #   })
    #   [
    #     "jellyfin"
    #     "seerr"
    #     "audiobookshelf"
    #     "calibre-web"
    #   ];

    time.timeZone = "America/Toronto";

    system.stateVersion = "26.05";
    home-manager.users.${userName}.home.stateVersion = "26.05";
  };
}
