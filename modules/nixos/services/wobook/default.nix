{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.services.wobook;
in
{
  # System firewall for sync (UDP 47390-47399) and mDNS (UDP 5353).
  imports = [ inputs.wobook.nixosModules.wobook ];

  options._custom.services.wobook = {
    enable = lib.mkEnableOption "wobook local-first bookmarks";
    chromiumExtensionIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Ids shown on chrome://extensions after "Load unpacked" of
        `nix build github:wochap/wobook#extension-chromium`. With browsers.enable, non-empty enables
        the Brave and Google Chrome native messaging hosts.
      '';
    };
  };

  config = {
    # Set unconditionally: openFirewall defaults to true in the upstream module.
    services.wobook.openFirewall = cfg.enable;

    _custom.hm = lib.mkIf cfg.enable {
      imports = [ inputs.wobook.homeManagerModules.wobook ];

      programs.wobook = {
        enable = true;
        daemon.enable = true;
        fzf.enable = true;
        deviceName = config.networking.hostName;
        hooks."pre-add.strip-utm" = "${inputs.wobook}/contrib/hooks/pre-add.strip-utm";
        browsers = {
          firefox.enable = true;
          brave.enable = cfg.chromiumExtensionIds != [ ];
          googleChrome.enable = cfg.chromiumExtensionIds != [ ];
          inherit (cfg) chromiumExtensionIds;
        };
      };
    };
  };
}
