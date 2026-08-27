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
in
{
  options._custom.desktop.home-screen.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    services.glance = {
      enable = true;
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
            hide-desktop-navigation = true;
            columns = [
              {
                size = "full";
                widgets = [
                  {
                    type = "markets";
                    title = "Crypto";
                    markets = [
                      {
                        symbol = "BTC-USD";
                        name = "Bitcoin";
                      }
                      {
                        symbol = "XMR-USD";
                        name = "Monero";
                      }
                    ];
                  }
                  {
                    type = "markets";
                    title = "Markets";
                    markets = [
                      {
                        symbol = "SPY";
                        name = "S&P 500";
                      }
                      {
                        symbol = "QQQ";
                        name = "Nasdaq 100";
                      }
                      {
                        symbol = "IWM";
                        name = "Russell 2000";
                      }
                      {
                        symbol = "ARTY";
                        name = "AI & Tech";
                      }
                    ];
                  }
                  {
                    type = "markets";
                    title = "Commodities";
                    markets = [
                      {
                        symbol = "GC=F";
                        name = "Gold";
                      }
                      {
                        symbol = "CL=F";
                        name = "Crude Oil";
                      }
                      {
                        symbol = "NG=F";
                        name = "Natural Gas";
                      }
                    ];
                  }
                  {
                    type = "markets";
                    title = "Food";
                    markets = [
                      {
                        symbol = "ZC=F";
                        name = "Corn";
                      }
                      {
                        symbol = "ZW=F";
                        name = "Wheat";
                      }
                      {
                        symbol = "ZS=F";
                        name = "Soybeans";
                      }
                      {
                        symbol = "LE=F";
                        name = "Live Cattle";
                      }
                    ];
                  }
                  {
                    type = "markets";
                    title = "Peru";
                    markets = [
                      {
                        symbol = "PEN=X";
                        name = "USD / PEN";
                      }
                    ];
                  }
                ];
              }
            ];
          }
        ];
      };
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
