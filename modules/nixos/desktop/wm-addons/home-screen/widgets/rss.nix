{
  # Official sources: low-noise, potentially high-impact.
  fedSec = {
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
  };

  # Main dashboard news stream.
  marketNews = {
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
  };

  aiNews = {
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
  };

  # Compact secondary news stream for macro events affecting
  # commodities, currencies and indexes.
  macroNews = {
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
  };
}
