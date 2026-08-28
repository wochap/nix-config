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
              # -----------------------------------------------------------------------
              # LEFT: Macro / sector overview
              # -----------------------------------------------------------------------
              {
                size = "small";

                widgets = [
                  {
                    type = "markets";
                    title = "Macro";
                    chart-link-template = "https://www.tradingview.com/chart/?symbol={SYMBOL}";

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
                        symbol = "DX-Y.NYB";
                        name = "US Dollar Index";
                      }
                    ];
                  }

                  {
                    type = "markets";
                    title = "Semiconductors";
                    chart-link-template = "https://www.tradingview.com/chart/?symbol={SYMBOL}";

                    markets = [
                      {
                        symbol = "SMH";
                        name = "VanEck Semiconductor";
                      }
                      {
                        symbol = "SOXX";
                        name = "iShares Semiconductor";
                      }
                    ];
                  }

                  {
                    type = "markets";
                    title = "Crypto";
                    chart-link-template = "https://www.tradingview.com/chart/?symbol={SYMBOL}";

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
                    title = "Peru";
                    chart-link-template = "https://www.tradingview.com/chart/?symbol={SYMBOL}";

                    markets = [
                      {
                        symbol = "PEN=X";
                        name = "USD / PEN";
                      }
                    ];
                  }

                  # Official sources: low-noise, potentially high-impact.
                  {
                    type = "rss";
                    title = "Fed / SEC";
                    limit = 12;
                    collapse-after = 6;
                    cache = "15m";

                    feeds = [
                      {
                        url = "https://www.federalreserve.gov/feeds/press_all.xml";
                        title = "Federal Reserve";
                      }
                      {
                        url = "https://www.sec.gov/news/pressreleases.rss";
                        title = "SEC";
                      }
                    ];
                  }
                ];
              }

              # -----------------------------------------------------------------------
              # CENTER: News + AI supply chain
              # -----------------------------------------------------------------------
              {
                size = "full";

                widgets = [
                  # Main dashboard news stream.
                  {
                    type = "rss";
                    title = "Market Moving News";
                    style = "horizontal-cards";
                    limit = 20;
                    collapse-after = 10;
                    cache = "10m";

                    feeds = [
                      {
                        url = "https://feeds.bloomberg.com/markets/news.rss";
                        title = "Bloomberg Markets";
                      }
                      {
                        url = "https://moxie.foxbusiness.com/google-publisher/markets.xml";
                        title = "Fox Business Markets";
                      }
                      {
                        url = "https://feeds.a.dj.com/rss/RSSMarketsMain.xml";
                        title = "WSJ Markets";
                      }
                    ];
                  }

                  {
                    type = "rss";
                    title = "AI / Semiconductor News";
                    style = "horizontal-cards";
                    limit = 16;
                    collapse-after = 8;
                    cache = "15m";

                    feeds = [
                      {
                        url = "https://www.ft.com/technology?format=rss";
                        title = "Financial Times Tech";
                      }
                      {
                        url = "https://moxie.foxbusiness.com/google-publisher/technology.xml";
                        title = "Fox Business Tech";
                      }
                    ];
                  }

                  {
                    type = "markets";
                    title = "AI Compute";
                    chart-link-template = "https://www.tradingview.com/chart/?symbol={SYMBOL}";

                    markets = [
                      {
                        symbol = "NVDA";
                        name = "NVIDIA";
                      }
                      {
                        symbol = "AMD";
                        name = "AMD";
                      }
                      {
                        symbol = "INTC";
                        name = "Intel";
                      }
                      {
                        symbol = "AVGO";
                        name = "Broadcom";
                      }
                      {
                        symbol = "ARM";
                        name = "Arm";
                      }
                    ];
                  }

                  {
                    type = "markets";
                    title = "Foundries";
                    chart-link-template = "https://www.tradingview.com/chart/?symbol={SYMBOL}";

                    markets = [
                      {
                        symbol = "TSM";
                        name = "TSMC";
                      }
                      {
                        symbol = "005930.KS";
                        name = "Samsung Electronics";
                      }
                    ];
                  }

                  {
                    type = "markets";
                    title = "HBM / DRAM / NAND";
                    chart-link-template = "https://www.tradingview.com/chart/?symbol={SYMBOL}";

                    markets = [
                      {
                        symbol = "MU";
                        name = "Micron";
                      }
                      {
                        symbol = "000660.KS";
                        name = "SK Hynix";
                      }
                      {
                        symbol = "005930.KS";
                        name = "Samsung";
                      }
                    ];
                  }

                  {
                    type = "markets";
                    title = "Semiconductor Equipment";
                    chart-link-template = "https://www.tradingview.com/chart/?symbol={SYMBOL}";

                    markets = [
                      {
                        symbol = "ASML";
                        name = "ASML";
                      }
                      {
                        symbol = "AMAT";
                        name = "Applied Materials";
                      }
                      {
                        symbol = "LRCX";
                        name = "Lam Research";
                      }
                      {
                        symbol = "KLAC";
                        name = "KLA";
                      }
                      {
                        symbol = "TER";
                        name = "Teradyne";
                      }
                    ];
                  }

                  {
                    type = "markets";
                    title = "Networking / Interconnect";
                    chart-link-template = "https://www.tradingview.com/chart/?symbol={SYMBOL}";

                    markets = [
                      {
                        symbol = "AVGO";
                        name = "Broadcom";
                      }
                      {
                        symbol = "MRVL";
                        name = "Marvell";
                      }
                      {
                        symbol = "ANET";
                        name = "Arista Networks";
                      }
                    ];
                  }

                  {
                    type = "markets";
                    title = "Packaging / Assembly";
                    chart-link-template = "https://www.tradingview.com/chart/?symbol={SYMBOL}";

                    markets = [
                      {
                        symbol = "AMKR";
                        name = "Amkor";
                      }
                      {
                        symbol = "ASX";
                        name = "ASE Technology";
                      }
                    ];
                  }
                ];
              }

              # -----------------------------------------------------------------------
              # RIGHT: AI demand + physical economy
              # -----------------------------------------------------------------------
              {
                size = "small";

                widgets = [
                  {
                    type = "markets";
                    title = "Hyperscalers";
                    chart-link-template = "https://www.tradingview.com/chart/?symbol={SYMBOL}";

                    markets = [
                      {
                        symbol = "MSFT";
                        name = "Microsoft";
                      }
                      {
                        symbol = "GOOGL";
                        name = "Alphabet";
                      }
                      {
                        symbol = "AMZN";
                        name = "Amazon";
                      }
                      {
                        symbol = "META";
                        name = "Meta";
                      }
                      {
                        symbol = "ORCL";
                        name = "Oracle";
                      }
                    ];
                  }

                  {
                    type = "markets";
                    title = "AI Servers";
                    chart-link-template = "https://www.tradingview.com/chart/?symbol={SYMBOL}";

                    markets = [
                      {
                        symbol = "SMCI";
                        name = "Super Micro";
                      }
                      {
                        symbol = "DELL";
                        name = "Dell";
                      }
                      {
                        symbol = "HPE";
                        name = "HPE";
                      }
                    ];
                  }

                  {
                    type = "markets";
                    title = "Power / Cooling";
                    chart-link-template = "https://www.tradingview.com/chart/?symbol={SYMBOL}";

                    markets = [
                      {
                        symbol = "VRT";
                        name = "Vertiv";
                      }
                      {
                        symbol = "ETN";
                        name = "Eaton";
                      }
                      {
                        symbol = "GEV";
                        name = "GE Vernova";
                      }
                      {
                        symbol = "CEG";
                        name = "Constellation Energy";
                      }
                    ];
                  }

                  {
                    type = "markets";
                    title = "Commodities";
                    chart-link-template = "https://www.tradingview.com/chart/?symbol={SYMBOL}";

                    markets = [
                      {
                        symbol = "GC=F";
                        name = "Gold";
                      }
                      {
                        symbol = "HG=F";
                        name = "Copper";
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
                    chart-link-template = "https://www.tradingview.com/chart/?symbol={SYMBOL}";

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

                  # Compact secondary news stream for macro events affecting
                  # commodities, currencies and indexes.
                  {
                    type = "rss";
                    title = "Macro News";
                    limit = 20;
                    collapse-after = 8;
                    cache = "15m";

                    feeds = [
                      {
                        url = "https://feeds.bloomberg.com/markets/news.rss";
                        title = "Bloomberg";
                      }
                      {
                        url = "https://moxie.foxbusiness.com/google-publisher/markets.xml";
                        title = "Fox Business";
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
