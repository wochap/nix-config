let
  nixpkgs = builtins.getFlake "nixpkgs";
  inherit (nixpkgs) lib;
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  base = {
    nixpkgs.hostPlatform = "x86_64-linux";
    boot.loader.grub.enable = false;
    fileSystems."/" = {
      device = "/dev/sda1";
      fsType = "ext4";
    };
  };
  system = modules: lib.nixosSystem { modules = [ base ] ++ modules; };
  eval = modules: (system modules).config;
  # Evaluate deeply; turn catchable errors into a marker so every case is reported.
  try =
    v:
    let
      r = builtins.tryEval (builtins.deepSeq v v);
    in
    if r.success then r.value else "<evaluation error>";
  sortList = l: if builtins.isList l then lib.sort lib.lessThan l else l;
  failedAssertions =
    c: try (map (a: a.message) (builtins.filter (a: !a.assertion) (c.assertions or [ ])));
  svc = c: name: c.systemd.services.${name} or { };
  # Missing options are not catchable by tryEval; look them up with a fallback.
  get = path: c: try (lib.attrByPath (lib.splitString "." path) "<missing>" c);
  svcAttr =
    c: name: path:
    try (lib.attrByPath path "<missing>" (c.systemd.services.${name} or { }));
  hasPkg = c: p: try (builtins.any (x: (x.outPath or "") == p.outPath) c.environment.systemPackages);

  host = eval [ ../host.nix ];
  web = system [
    ../tinyweb.nix
    { system.stateVersion = "26.05"; }
  ];
  webOff = web.config;
  webHello = eval [
    ../tinyweb.nix
    {
      system.stateVersion = "26.05";
      networking.firewall.allowedTCPPorts = [ 443 ];
      services.tinyweb = {
        enable = true;
        package = pkgs.hello;
        sites.a = {
          port = 9001;
          root = "/srv/a b";
          openFirewall = true;
        };
        sites.b = {
          port = 9002;
          root = "/srv/b";
          openFirewall = true;
        };
      };
    }
  ];
  webDup = eval [
    ../tinyweb.nix
    {
      system.stateVersion = "26.05";
      services.tinyweb = {
        enable = true;
        sites = {
          one = {
            port = 8081;
            root = "/srv/1";
          };
          two = {
            port = 8081;
            root = "/srv/2";
          };
          three = {
            port = 8083;
            root = "/srv/3";
          };
        };
      };
    }
  ];
  webBadPort = eval [
    ../tinyweb.nix
    {
      system.stateVersion = "26.05";
      services.tinyweb = {
        enable = true;
        sites.x = {
          port = 65536;
          root = "/srv/x";
        };
      };
    }
  ];
  webDisabledSites = eval [
    ../tinyweb.nix
    {
      system.stateVersion = "26.05";
      services.tinyweb.sites.a = {
        port = 9001;
        root = "/srv/a";
        openFirewall = true;
      };
    }
  ];
  darkhttpd = lib.getExe pkgs.darkhttpd;
  hello = lib.getExe pkgs.hello;
  tinywebServices =
    c: try (builtins.filter (lib.hasPrefix "tinyweb-") (builtins.attrNames c.systemd.services));

  cases = [
    # host.nix
    {
      name = "host: no warnings";
      got = try host.warnings;
      want = [ ];
    }
    {
      name = "host: no failing assertions";
      got = failedAssertions host;
      want = [ ];
    }
    {
      name = "host: hostName";
      got = get "networking.hostName" host;
      want = "web1";
    }
    {
      name = "host: stateVersion";
      got = get "system.stateVersion" host;
      want = "26.05";
    }
    {
      name = "host: openssh";
      got = {
        enable = get "services.openssh.enable" host;
        PermitRootLogin = get "services.openssh.settings.PermitRootLogin" host;
        PasswordAuthentication = get "services.openssh.settings.PasswordAuthentication" host;
      };
      want = {
        enable = true;
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    }
    {
      name = "host: graphics";
      got = {
        enable = get "hardware.graphics.enable" host;
        enable32Bit = get "hardware.graphics.enable32Bit" host;
      };
      want = {
        enable = true;
        enable32Bit = true;
      };
    }
    {
      name = "host: audio";
      got = {
        pipewire = get "services.pipewire.enable" host;
        alsa = get "services.pipewire.alsa.enable" host;
        pulse = get "services.pipewire.pulse.enable" host;
        pulseaudio = get "services.pulseaudio.enable" host;
      };
      want = {
        pipewire = true;
        alsa = true;
        pulse = true;
        pulseaudio = false;
      };
    }
    {
      name = "host: default fonts enabled";
      got = get "fonts.enableDefaultPackages" host;
      want = true;
    }
    {
      name = "host: noto-fonts installed";
      got = try (
        builtins.any (p: (p.outPath or "") == pkgs.noto-fonts.outPath) (host.fonts.packages or [ ])
      );
      want = true;
    }
    {
      name = "host: experimental features";
      got = get "nix.settings.experimental-features" host;
      want = [
        "nix-command"
        "flakes"
      ];
    }
    {
      name = "host: alice";
      got = {
        isNormalUser = get "users.users.alice.isNormalUser" host;
        groups = sortList (get "users.users.alice.extraGroups" host);
        shell = try (host.users.users.alice.shell.outPath or null);
      };
      want = {
        isNormalUser = true;
        groups = [
          "networkmanager"
          "wheel"
        ];
        shell = pkgs.zsh.outPath;
      };
    }
    {
      name = "host: tinyweb services";
      got = tinywebServices host;
      want = [
        "tinyweb-docs"
        "tinyweb-wiki"
      ];
    }
    {
      name = "host: tinyweb-docs ExecStart";
      got = svcAttr host "tinyweb-docs" [
        "serviceConfig"
        "ExecStart"
      ];
      want = "${darkhttpd} /srv/docs --port 8081 --index index.html";
    }
    {
      name = "host: tinyweb-wiki ExecStart";
      got = svcAttr host "tinyweb-wiki" [
        "serviceConfig"
        "ExecStart"
      ];
      want = "${darkhttpd} /srv/wiki --port 8082 --index Home.html";
    }
    {
      name = "host: tinyweb-docs unit settings";
      got = {
        wantedBy = svcAttr host "tinyweb-docs" [ "wantedBy" ];
        after = try (builtins.elem "network.target" ((svc host "tinyweb-docs").after or [ ]));
        DynamicUser = svcAttr host "tinyweb-docs" [
          "serviceConfig"
          "DynamicUser"
        ];
        Restart = svcAttr host "tinyweb-docs" [
          "serviceConfig"
          "Restart"
        ];
      };
      want = {
        wantedBy = [ "multi-user.target" ];
        after = true;
        DynamicUser = true;
        Restart = "on-failure";
      };
    }
    {
      name = "host: firewall ports (ssh + docs only)";
      got = sortList (try host.networking.firewall.allowedTCPPorts);
      want = [
        22
        8081
      ];
    }
    {
      name = "host: darkhttpd installed";
      got = hasPkg host pkgs.darkhttpd;
      want = true;
    }

    # tinyweb.nix alone
    {
      name = "module: enable default";
      got = get "services.tinyweb.enable" webOff;
      want = false;
    }
    {
      name = "module: package default is darkhttpd";
      got = try ((webOff.services.tinyweb.package or { }).outPath or "<missing>");
      want = pkgs.darkhttpd.outPath;
    }
    {
      name = "module: sites default";
      got = get "services.tinyweb.sites" webOff;
      want = { };
    }
    {
      name = "module: disabled adds nothing";
      got = try {
        services = tinywebServices webOff;
        darkhttpd = hasPkg webOff pkgs.darkhttpd;
      };
      want = {
        services = [ ];
        darkhttpd = false;
      };
    }
    {
      name = "module: disabled with sites adds nothing";
      got = try {
        services = tinywebServices webDisabledSites;
        ports = webDisabledSites.networking.firewall.allowedTCPPorts;
      };
      want = {
        services = [ ];
        ports = [ ];
      };
    }
    {
      name = "module: custom package ExecStart";
      got = svcAttr webHello "tinyweb-a" [
        "serviceConfig"
        "ExecStart"
      ];
      want = "${hello} /srv/a b --port 9001 --index index.html";
    }
    {
      name = "module: custom package installed";
      got = hasPkg webHello pkgs.hello;
      want = true;
    }
    {
      name = "module: firewall merges with other modules";
      got = sortList (try webHello.networking.firewall.allowedTCPPorts);
      want = [
        443
        9001
        9002
      ];
    }
    {
      name = "module: no warnings or failing assertions";
      got = try (webHello.warnings ++ failedAssertions webHello ++ webOff.warnings);
      want = [ ];
    }
    {
      name = "module: duplicate port assertion";
      got =
        let
          msgs = failedAssertions webDup;
        in
        if builtins.isList msgs then
          builtins.any (m: lib.hasInfix "tinyweb" m && lib.hasInfix "8081" m) msgs
          && !(builtins.any (lib.hasInfix "8083") msgs)
        else
          msgs;
      want = true;
    }
    {
      name = "module: port 65536 rejected";
      got = svcAttr webBadPort "tinyweb-x" [
        "serviceConfig"
        "ExecStart"
      ];
      want = "<evaluation error>";
    }
  ];
  failed = builtins.filter (c: c.got != c.want) cases;
  show = c: "FAIL ${c.name}: got ${builtins.toJSON c.got}, want ${builtins.toJSON c.want}";
in
if failed == [ ] then
  "ok: ${toString (builtins.length cases)} tests passed"
else
  throw ("\n" + lib.concatMapStringsSep "\n" show failed)
