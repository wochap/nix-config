{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.desktop.home-screen;
  inherit (pkgs._custom) wochap-ssc;
  proxy = config._custom.services.web-proxies.home-screen;
  personalSopsFile = ../../../../../secrets-sops/personal.yaml;
  widgets = import ./widgets {
    inherit lib;
    finnhub = cfg.finnhub.enable;
    fred = cfg.fred.enable;
  };
  inherit (widgets) markets mkMarketsWidget;
in
{
  options._custom.desktop.home-screen = {
    enable = lib.mkEnableOption { };

    # Free API keys stored in secrets-sops/personal.yaml. Keep disabled until
    # the key exists there, otherwise sops-nix activation fails.
    finnhub.enable = lib.mkEnableOption "Finnhub valuation, analyst, news and earnings data (personal-finnhub-api-key)";
    fred.enable = lib.mkEnableOption "FRED macro rates (personal-fred-api-key)";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.finnhub.enable || cfg.fred.enable) -> config._custom.security.sops.enable;
        message = "home-screen: finnhub/fred need _custom.security.sops.enable";
      }
    ];

    services.glance = {
      enable = true;
      environmentFile = lib.mkIf (
        cfg.finnhub.enable || cfg.fred.enable
      ) config.sops.templates."glance.env".path;
      openFirewall = false;
      settings = {
        server = {
          host = wochap-ssc.meta.address;
          port = proxy.backendPort;
        };
        theme = {
          presets = {
            default-dark = {
              background-color = "240 21 15";
              contrast-multiplier = 1.2;
              primary-color = "217 92 83";
              positive-color = "115 54 76";
              negative-color = "347 70 65";
            };

            default-light = {
              light = true;
              background-color = "220 23 95";
              contrast-multiplier = 1.1;
              primary-color = "220 91 54";
              positive-color = "109 58 40";
              negative-color = "347 87 44";
            };
          };
        };
        pages = [
          {
            name = "Markets";

            columns = [
              # -----------------------------------------------------------------------
              # LEFT: Macro / sector overview + sentiment
              # -----------------------------------------------------------------------
              {
                size = "small";

                widgets = [
                  widgets.styles
                  (mkMarketsWidget markets.macro)
                  widgets.fearGreed
                ]
                ++ lib.optional cfg.fred.enable widgets.macroRates
                ++ [
                  (mkMarketsWidget markets.semiconductors)
                  (mkMarketsWidget markets.crypto)
                  (mkMarketsWidget markets.peru)
                  widgets.rss.fedSec
                ];
              }

              # -----------------------------------------------------------------------
              # CENTER: News + AI supply chain
              # -----------------------------------------------------------------------
              {
                size = "full";

                widgets = [
                  widgets.rss.marketNews
                  widgets.rss.aiNews
                ]
                ++ lib.optional cfg.finnhub.enable widgets.earnings
                ++ map mkMarketsWidget [
                  markets.aiCompute
                  markets.foundries
                  markets.memory
                  markets.equipment
                  markets.networking
                  markets.packaging
                ];
              }

              # -----------------------------------------------------------------------
              # RIGHT: AI demand + physical economy
              # -----------------------------------------------------------------------
              {
                size = "small";

                widgets =
                  map mkMarketsWidget [
                    markets.hyperscalers
                    markets.aiServers
                    markets.power
                    markets.commodities
                    markets.food
                  ]
                  ++ [ widgets.rss.macroNews ];
              }
            ];
          }

          # Tall chart cards (1M / 3M / 1Y + signals) for every watchlist symbol.
          {
            name = "Charts";

            columns = [
              {
                size = "full";

                widgets = [
                  widgets.styles
                  widgets.rangeControl
                ]
                ++ widgets.mkChartSections [
                  "macro"
                  "aiCompute"
                  "foundries"
                  "memory"
                  "equipment"
                  "networking"
                  "packaging"
                  "hyperscalers"
                  "aiServers"
                  "power"
                  "semiconductors"
                  "crypto"
                  "commodities"
                  "food"
                  "peru"
                ];
              }
            ];
          }
        ];
      };
    };

    sops.secrets = lib.mkMerge [
      (lib.mkIf cfg.finnhub.enable {
        personal-finnhub-api-key.sopsFile = personalSopsFile;
      })
      (lib.mkIf cfg.fred.enable {
        personal-fred-api-key.sopsFile = personalSopsFile;
      })
    ];

    sops.templates."glance.env" = lib.mkIf (cfg.finnhub.enable || cfg.fred.enable) {
      mode = "0400";
      restartUnits = [ "glance.service" ];
      content =
        lib.optionalString cfg.finnhub.enable ''
          FINNHUB_API_KEY=${config.sops.placeholder.personal-finnhub-api-key}
        ''
        + lib.optionalString cfg.fred.enable ''
          FRED_API_KEY=${config.sops.placeholder.personal-fred-api-key}
        '';
    };

    systemd.services.glance.serviceConfig = lib._custom.strictNetworkService // {
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictNamespaces = true;
      MemoryDenyWriteExecute = true;
      ProtectProc = "invisible";
    };

    _custom.services.web-proxies.home-screen = {
      enable = true;
      subdomain = "home-screen";
      serviceName = "glance";
      publicPort = 18080;
      backendPort = 18081;
      lazy = true;
    };
  };
}
