{
  config,
  pkgs,
  lib,
  ...
}:

# `article` CLI. Each internal tool under ./<tool>/package.nix does one job;
# ./package.nix (`article`) exposes them as subcommands and chains them. This
# module wires them to the system: the command, the library server and its proxy.
let
  cfg = config._custom.services.ai;
  proxy = config._custom.services.web-gate.proxies.article-library;
  inherit (pkgs._custom) wochap-ssc;
  inherit (config._custom.globals) userName;

  article-scrape = pkgs.callPackage ./scrape/package.nix { };
  article-render = pkgs.callPackage ./render/package.nix { };
  article-summarize = pkgs.callPackage ./summarize/package.nix { };
  article-library = pkgs.callPackage ./library/package.nix {
    inherit article-render;
    url = "https://${proxy.subdomain}.${wochap-ssc.meta.domain}";
  };
  article = pkgs.callPackage ./package.nix {
    inherit
      article-scrape
      article-summarize
      article-render
      article-library
      ;
  };
in
{
  options._custom.services.ai.enableArticle = lib.mkEnableOption { };

  config = lib.mkIf (cfg.enable && cfg.enableArticle) {
    assertions = [
      {
        assertion = cfg.enableOmniRoute;
        message = "_custom.services.ai.enableArticle requires enableOmniRoute.";
      }
    ];

    # Only the front command is public; the tools are its internals.
    environment.systemPackages = [ article ];

    # Faces the article-render stylesheet asks for; installed so pages render offline.
    fonts.packages = with pkgs; [
      source-serif
      ibm-plex
      jetbrains-mono
    ];

    _custom.services.web-gate.proxies.article-library = {
      enable = true;
      subdomain = "articles";
      publicPort = 20700;
      backendPort = 20701;
      serviceName = "article-library";
      lazy = true;
      serviceScope = "user";
      inherit userName;
    };

    # Read-only static server over the user's library, so it runs as the user.
    # %D is $XDG_DATA_HOME, the same default article-library uses.
    _custom.hm.systemd.user.services.article-library = {
      Unit.Description = "Article library static server";
      Service = {
        Environment = [ "ARTICLE_LIBRARY_DIR=%D/article-library" ];
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p %D/article-library"
          # "-": a failed list rebuild must not keep the pages offline.
          "-${lib.getExe article-library} index"
        ];
        ExecStart = "${lib.getExe pkgs.python3} -m http.server --bind ${wochap-ssc.meta.address} --directory %D/article-library ${toString proxy.backendPort}";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
