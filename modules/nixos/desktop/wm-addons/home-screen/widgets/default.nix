# Widget builders for the home-screen Glance dashboard.
#
# Templates live in ./templates as plain Go html/template files and are
# preprocessed here with `builtins.replaceStrings`:
#   @TIP_<NAME>@      tooltip text from ./glossary.nix (name upper-cased)
#   @FINNHUB_TOKEN@   Glance env reference, empty when Finnhub is disabled
#   @FRED_TOKEN@      Glance env reference, empty when FRED is disabled
#
# Glance aborts at startup when a `${VAR}` reference is unset, so the env
# references are only emitted when the matching API key is configured.
{
  lib,
  finnhub ? false,
  fred ? false,
}:

let
  markets = import ../markets.nix;
  glossary = import ./glossary.nix;
  rss = import ./rss.nix;

  chartLink = "https://www.tradingview.com/chart/?symbol={SYMBOL}";

  substitute = vars: text: builtins.replaceStrings (lib.attrNames vars) (lib.attrValues vars) text;

  globalVars =
    lib.mapAttrs' (name: lib.nameValuePair "@TIP_${lib.toUpper name}@") glossary
    // {
      "@FINNHUB_TOKEN@" = lib.optionalString finnhub "\${FINNHUB_API_KEY}";
      "@FRED_TOKEN@" = lib.optionalString fred "\${FRED_API_KEY}";
    };

  readTemplate = name: builtins.readFile (./templates + "/${name}");

  render = extraVars: name: substitute (globalVars // extraVars) (readTemplate name);

  # Chart ranges rendered as CSS-only tabs. All come from one 1y request;
  # `seconds` is the window measured back from the last data point.
  ranges = [
    {
      key = "1m";
      label = "1M";
      seconds = 31 * 86400;
    }
    {
      key = "3m";
      label = "3M";
      seconds = 92 * 86400;
    }
    {
      key = "1y";
      label = "1Y";
      seconds = 400 * 86400;
    }
  ];

  renderRanges =
    snippet:
    lib.concatMapStrings (
      range:
      substitute {
        "@KEY@" = range.key;
        "@LABEL@" = range.label;
        "@SECONDS@" = toString range.seconds;
      } (readTemplate snippet)
    ) ranges;

  stockChartTemplate = render {
    "@RANGE_CALCS@" = renderRanges "range-calc.html";
    "@RANGE_TABS@" = renderRanges "range-tab.html";
    "@RANGE_CHARTS@" = renderRanges "range-chart.html";
  } "stock-chart.html";

  # Plain US tickers have Finnhub coverage; futures (=F), FX (=X), crypto
  # (-USD), indexes (^) and foreign listings (.KS) do not.
  isUsEquity = symbol: !(lib.any (c: lib.hasInfix c symbol) [ "=" "-" "." "^" ]);

  hasFundamentals = market: finnhub && (market.fundamentals or (isUsEquity market.symbol));

  htmlId = symbol: builtins.replaceStrings [ "=" "." "^" "-" ] [ "_" "_" "_" "_" ] symbol;

  # Frameless widget without a request: renders static HTML once.
  mkStatic = template: {
    type = "custom-api";
    frameless = true;
    hide-header = true;
    cache = "24h";
    inherit template;
  };
in
rec {
  inherit markets rss;

  # Compact rows with a 1-month sparkline (built-in Glance widget).
  mkMarketsWidget = group: {
    type = "markets";
    inherit (group) title;
    chart-link-template = chartLink;
    markets = map (market: { inherit (market) symbol name; }) group.markets;
  };

  # Tall card: 1M/3M/1Y chart, technical signals and, for US equities with a
  # Finnhub key, valuation, analyst consensus and company news.
  mkStockChartWidget = market: {
    type = "custom-api";
    title = "${market.name} (${market.symbol})";
    title-url = builtins.replaceStrings [ "{SYMBOL}" ] [ market.symbol ] chartLink;
    cache = "2h";
    url = "https://query1.finance.yahoo.com/v8/finance/chart/${market.symbol}";
    parameters = {
      range = "1y";
      interval = "1d";
    };
    headers."User-Agent" =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:149.0) Gecko/20100101 Firefox/149.0";
    options = {
      inherit (market) symbol;
      uid = htmlId market.symbol;
      fundamentals = hasFundamentals market;
    };
    template = stockChartTemplate;
  };

  # Shared CSS for every custom widget; include once per page.
  styles = mkStatic "<style>${readTemplate "styles.css"}</style>";

  mkHeading = title: mkStatic ''<h2 class="size-h3 color-highlight uppercase" style="margin-top: 10px">${title}</h2>'';

  fearGreed = {
    type = "custom-api";
    title = "Fear & Greed";
    cache = "1h";
    url = "https://api.alternative.me/fng/";
    parameters.limit = "2";
    template = render { } "fear-greed.html";
  };

  # Upcoming earnings for every US equity in the watchlist.
  earnings = lib.optionalAttrs finnhub {
    type = "custom-api";
    title = "Earnings Calendar";
    cache = "6h";
    options.symbols = lib.concatStringsSep "|" (
      lib.unique (
        map (market: market.symbol) (
          lib.filter hasFundamentals (lib.concatMap (group: group.markets) (lib.attrValues markets))
        )
      )
    );
    template = render { } "earnings.html";
  };

  macroRates = lib.optionalAttrs fred {
    type = "custom-api";
    title = "Macro Rates";
    cache = "12h";
    template =
      ''<ul class="list list-gap-14 list-with-separator">''
      +
        lib.concatMapStrings
          (
            series:
            render {
              "@SERIES@" = series.id;
              "@LABEL@" = series.label;
              "@UNITS@" = series.units or "lin";
              "@TIP@" = glossary.${series.tip};
              # rising rates / inflation / unemployment is bad for stocks
              "@UP_COLOR@" = "negative";
              "@DOWN_COLOR@" = "positive";
            } "fred-row.html"
          )
          [
            {
              id = "FEDFUNDS";
              label = "Fed funds rate";
              tip = "fedFunds";
            }
            {
              id = "DGS10";
              label = "10Y Treasury";
              tip = "treasury10y";
            }
            {
              id = "T10Y2Y";
              label = "Yield curve 10Y-2Y";
              tip = "yieldCurve";
            }
            {
              id = "CPIAUCSL";
              label = "CPI inflation YoY";
              units = "pc1";
              tip = "cpi";
            }
            {
              id = "UNRATE";
              label = "Unemployment";
              tip = "unemployment";
            }
          ]
      + "</ul>";
  };

  # One heading + card grid per watchlist group, symbols deduplicated across
  # groups (first group wins).
  mkChartSections =
    groupNames:
    let
      step =
        acc: name:
        let
          group = markets.${name};
          fresh = lib.filter (market: !(acc.seen ? ${market.symbol})) group.markets;
        in
        {
          seen = acc.seen // lib.genAttrs (map (market: market.symbol) fresh) (_: true);
          widgets =
            acc.widgets
            ++ lib.optionals (fresh != [ ]) [
              (mkHeading group.title)
              {
                type = "split-column";
                max-columns = 3;
                widgets = map mkStockChartWidget fresh;
              }
            ];
        };
    in
    (lib.foldl' step {
      seen = { };
      widgets = [ ];
    } groupNames).widgets;
}
