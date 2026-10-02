# Watchlist shared by the compact `markets` widgets (Markets page) and the
# stock chart cards (Charts page).
#
# `fundamentals` controls Finnhub valuation/news lookups. It defaults to true
# for plain US tickers (no `=`, `-`, `.` or `^` in the symbol); ETFs must opt
# out explicitly since Finnhub has no P/E or earnings for them.
#
# `signal = false` hides the buy-zone verdict for things you do not buy as an
# investment (volatility index, yields, currency rates).
{
  macro = {
    title = "Macro";
    markets = [
      {
        symbol = "SPY";
        name = "S&P 500";
        fundamentals = false;
      }
      {
        symbol = "QQQ";
        name = "Nasdaq 100";
        fundamentals = false;
      }
      {
        symbol = "IWM";
        name = "Russell 2000";
        fundamentals = false;
      }
      {
        symbol = "^VIX";
        name = "Volatility Index";
        signal = false;
      }
      {
        symbol = "^TNX";
        name = "US 10Y Yield";
        signal = false;
      }
      {
        symbol = "DX-Y.NYB";
        name = "US Dollar Index";
        signal = false;
      }
    ];
  };

  semiconductors = {
    title = "Semiconductors";
    markets = [
      {
        symbol = "SMH";
        name = "VanEck Semiconductor";
        fundamentals = false;
      }
      {
        symbol = "SOXX";
        name = "iShares Semiconductor";
        fundamentals = false;
      }
    ];
  };

  crypto = {
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
  };

  peru = {
    title = "Peru";
    markets = [
      {
        symbol = "PEN=X";
        name = "USD / PEN";
        signal = false;
      }
    ];
  };

  aiCompute = {
    title = "AI Compute";
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
  };

  foundries = {
    title = "Foundries";
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
  };

  memory = {
    title = "HBM / DRAM / NAND";
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
  };

  equipment = {
    title = "Semiconductor Equipment";
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
  };

  networking = {
    title = "Networking / Interconnect";
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
  };

  packaging = {
    title = "Packaging / Assembly";
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
  };

  hyperscalers = {
    title = "Hyperscalers";
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
  };

  aiServers = {
    title = "AI Servers";
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
  };

  power = {
    title = "Power / Cooling";
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
  };

  commodities = {
    title = "Commodities";
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
  };

  food = {
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
  };
}
