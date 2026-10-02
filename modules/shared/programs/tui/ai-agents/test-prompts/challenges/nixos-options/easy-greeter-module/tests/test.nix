let
  nixpkgs = builtins.getFlake "nixpkgs";
  inherit (nixpkgs) lib;
  base = {
    nixpkgs.hostPlatform = "x86_64-linux";
    system.stateVersion = "26.05";
    boot.loader.grub.enable = false;
    fileSystems."/" = {
      device = "/dev/sda1";
      fsType = "ext4";
    };
  };
  eval =
    cfg:
    (lib.nixosSystem {
      modules = [
        base
        ../module.nix
        cfg
      ];
    }).config;
  # Evaluate deeply; turn catchable errors into a marker so every case is reported.
  try =
    v:
    let
      r = builtins.tryEval (builtins.deepSeq v v);
    in
    if r.success then r.value else "<evaluation error>";
  etcText = c: try (c.environment.etc."greeter.conf".text or null);
  ports = c: try c.networking.firewall.allowedTCPPorts;
  opt = path: c: try (lib.attrByPath path "<missing>" c.services);

  off = eval { };
  on = eval {
    services.greeter = {
      enable = true;
      port = 9000;
      message = "Hi";
      openFirewall = true;
    };
  };
  defaults = eval { services.greeter.enable = true; };
  closed = eval {
    services.greeter = {
      enable = true;
      port = 9100;
    };
  };
  merged = eval {
    services.greeter = {
      enable = true;
      openFirewall = true;
    };
    networking.firewall.allowedTCPPorts = [ 443 ];
  };
  badPort = eval {
    services.greeter = {
      enable = true;
      port = 70000;
    };
  };
  badMsg = eval {
    services.greeter = {
      enable = true;
      message = 42;
    };
  };
  options =
    (lib.nixosSystem {
      modules = [
        base
        ../module.nix
      ];
    }).options.services;

  cases = [
    {
      name = "enable defaults to false";
      got = opt [ "greeter" "enable" ] off;
      want = false;
    }
    {
      name = "enable description";
      got = try (options.greeter.enable.description or null);
      want = "Whether to enable the greeter service.";
    }
    {
      name = "port default";
      got = opt [ "greeter" "port" ] off;
      want = 8080;
    }
    {
      name = "message default";
      got = opt [ "greeter" "message" ] off;
      want = "Hello";
    }
    {
      name = "openFirewall default";
      got = opt [ "greeter" "openFirewall" ] off;
      want = false;
    }
    {
      name = "disabled: no /etc/greeter.conf";
      got = try (off.environment.etc ? "greeter.conf");
      want = false;
    }
    {
      name = "disabled: firewall untouched";
      got = ports off;
      want = [ ];
    }
    {
      name = "enabled: greeter.conf text";
      got = etcText on;
      want = "port=9000\nmessage=Hi\n";
    }
    {
      name = "enabled: port opened";
      got = ports on;
      want = [ 9000 ];
    }
    {
      name = "enabled with defaults: greeter.conf text";
      got = etcText defaults;
      want = "port=8080\nmessage=Hello\n";
    }
    {
      name = "openFirewall false: port not opened";
      got = ports closed;
      want = [ ];
    }
    {
      name = "ports from other modules are kept";
      got =
        let
          p = ports merged;
        in
        if builtins.isList p then lib.sort lib.lessThan p else p;
      want = [
        443
        8080
      ];
    }
    {
      name = "port 70000 is rejected";
      got = etcText badPort;
      want = "<evaluation error>";
    }
    {
      name = "message must be a string";
      got = etcText badMsg;
      want = "<evaluation error>";
    }
    {
      name = "no warnings";
      got = try (on.warnings ++ off.warnings);
      want = [ ];
    }
  ];
  failed = builtins.filter (c: c.got != c.want) cases;
  show = c: "FAIL ${c.name}: got ${builtins.toJSON c.got}, want ${builtins.toJSON c.want}";
in
if failed == [ ] then
  "ok: ${toString (builtins.length cases)} tests passed"
else
  throw ("\n" + lib.concatMapStringsSep "\n" show failed)
