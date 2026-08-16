{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.services.rsshub;
  proxy = config._custom.services.web-proxies.rsshub;
in
{
  options._custom.services.rsshub.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets.personal-gh-token.sopsFile = ../../../../secrets-sops/personal.yaml;
      templates."rsshub.env" = {
        mode = "0400";
        content = ''
          GITHUB_ACCESS_TOKEN=${config.sops.placeholder.personal-gh-token}
        '';
      };
    };

    services.rsshub = {
      enable = true;
      openFirewall = false;
      redis.enable = true;
      secretFiles = [ config.sops.templates."rsshub.env".path ];
      settings = {
        LISTEN_INADDR_ANY = true;
        PORT = proxy.backendPort;
        PUPPETEER_EXECUTABLE_PATH = lib.getExe pkgs.chromium;
      };
    };

    systemd.services.rsshub.serviceConfig = lib._custom.strictNetworkService // {
      # Chromium needs user/mount namespaces for renderer isolation.
      # V8 JIT needs executable memory.
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
    };

    _custom.services.web-proxies.rsshub = {
      enable = true;
      subdomain = "rsshub";
      serviceName = "rsshub";
      publicPort = 1200;
      lazy = true;
    };
  };
}
