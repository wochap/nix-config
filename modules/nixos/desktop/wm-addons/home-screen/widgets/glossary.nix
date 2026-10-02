# Tooltip texts shown when hovering metrics. Each entry is injected into the
# templates as `@TIP_<NAME>@` (name upper-cased), so plain HTML is allowed but
# Go template syntax is not.
{
  price = "<b>Last price</b> in the listing currency. Today's change compares it with the previous session close.";
  range = "<b>Period change</b> from the first close of the selected range (1M / 3M / 1Y) to the last price.";

  technical = "<b>Technical signals</b> come from price history only. They help with <i>timing</i> (is it stretched or cheap right now?), not with whether the business is good.";
  rsi = "<b>RSI 14</b> (Relative Strength Index): momentum from 0 to 100 over the last 14 sessions. Above 70 is <i>overbought</i> (bought too fast, often pauses or pulls back). Below 30 is <i>oversold</i> (sold too fast, possible entry). 30 to 70 is neutral.";
  sma50 = "<b>SMA 50</b>: average close of the last 50 sessions, the medium-term trend. Price above it means buyers are in control lately.";
  sma200 = "<b>SMA 200</b>: average close of the last 200 sessions, the long-term trend. Price above it is a long-term uptrend; many investors avoid buying below it.";
  trend = "<b>Trend regime</b>: <i>Golden</i> when SMA 50 is above SMA 200 (uptrend), <i>Death</i> when below (downtrend). A fresh golden cross is a classic bullish signal.";
  week52 = "<b>52-week range</b>: where today's price sits between the lowest and highest price of the last year. Near the low can mean value or a falling knife; near the high means strength.";
  drawdown = "<b>From 52w high</b>: how far the price is below its 1-year peak. A large drawdown on a healthy company can be a discount; on a weak one it is a warning.";

  valuation = "<b>Valuation</b> compares the price with what the company earns, sells and owns. It tells you if the stock is <i>cheap or expensive</i>, best compared with peers in the same industry.";
  pe = "<b>P/E</b> (price / earnings, trailing 12 months): how many dollars you pay for $1 of yearly profit. Lower is cheaper. S&amp;P 500 average is roughly 20 to 25; fast growers usually trade higher.";
  peg = "<b>PEG</b>: P/E divided by the 5-year EPS growth rate. Adjusts P/E for growth. Below 1 is cheap for its growth, 1 to 2 is fair, above 2 is expensive.";
  ps = "<b>P/S</b> (price / sales): price per $1 of yearly revenue. Useful when profits are small or negative. Below 2 is cheap for most industries; software and chips often trade far higher.";
  pb = "<b>P/B</b> (price / book value): price per $1 of net assets. Below 1 can mean undervalued; asset-light tech companies usually trade high.";
  epsGrowth = "<b>EPS growth</b>: change in earnings per share over the last 12 months versus the year before. Rising profits support a rising price.";
  revGrowth = "<b>Revenue growth</b>: change in sales over the last 12 months versus the year before. Shows demand for the product.";
  margin = "<b>Net margin</b>: percent of revenue that becomes profit. Higher means pricing power and efficiency.";
  roe = "<b>ROE</b> (return on equity): profit per $1 of shareholder capital. Above 15% is strong.";
  beta = "<b>Beta</b>: volatility versus the market. 1 moves like the S&amp;P 500, 1.5 swings 50% more, below 1 is calmer.";
  dividend = "<b>Dividend yield</b>: yearly dividends as a percent of the price.";
  analysts = "<b>Analyst consensus</b>: latest count of Wall Street ratings (strong buy + buy / hold / sell + strong sell). Useful as sentiment, often late on turns.";

  verdict = "<b>Buy-zone checklist</b>: looks for a <i>pullback inside an uptrend</i>, a classic lower-risk entry. The long-term trend must be up, while the short term has cooled off. All checks passing earns the animated border.";

  news = "<b>Company news</b>: latest headlines from the last 7 days that mention this ticker.";

  earnings = "<b>Earnings calendar</b>: upcoming quarterly reports for your watchlist in the next 14 days. Prices often jump or drop 5 to 15% on these days. <i>BMO</i> = before market open, <i>AMC</i> = after market close.";
  epsEstimate = "<b>EPS estimate</b>: analysts' average expected earnings per share for the quarter. Beating it usually lifts the price.";

  fearGreed = "<b>Fear &amp; Greed</b>: crowd sentiment from 0 (extreme fear) to 100 (extreme greed). Extreme fear has historically been a better time to buy, extreme greed a time to be careful.";
  fearGreedStock = "<b>Stock market Fear &amp; Greed</b> (CNN): combines momentum, new highs vs lows, put/call options, junk bond demand, volatility (VIX) and safe-haven demand.";
  fearGreedCrypto = "<b>Crypto Fear &amp; Greed</b> (alternative.me): combines volatility, volume, social media, Bitcoin dominance and search trends.";

  fedFunds = "<b>Fed funds rate</b>: the US central bank policy rate. Cuts usually help stocks (cheaper money); hikes usually hurt growth stocks most.";
  treasury10y = "<b>10-year Treasury yield</b>: the risk-free long-term rate. Rising yields make future profits worth less today, pressuring high-P/E stocks.";
  yieldCurve = "<b>Yield curve (10Y minus 2Y)</b>: below 0 is <i>inverted</i>, which has preceded most US recessions. Re-steepening after an inversion is often when the slowdown arrives.";
  cpi = "<b>CPI inflation</b> (year over year): consumer price growth. The Fed targets 2%; higher inflation means fewer rate cuts.";
  unemployment = "<b>Unemployment rate</b>: a quick rise (about 0.5 points from the low) has historically signaled recession.";
}
