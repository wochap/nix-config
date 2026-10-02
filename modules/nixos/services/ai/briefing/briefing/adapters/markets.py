"""Facts adapter: market and macro numbers, computed here so the LLM never guesses them.

Highlights are {tag, text} with tag market, sentiment, macro or earnings.

Config: {key, mode, groups=[{title, markets=[{symbol, name, signal?}]}],
         fredSeries=[{id, label, units?}], fearGreed=true, earningsSymbols=[...],
         moveThreshold1d=3.0, moveThreshold1w=7.0}
Env: FRED_API_KEY, FINNHUB_API_KEY (optional; their parts are skipped when unset).
"""

import json
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta

from briefing.common import http_json, iso, log, now_utc

STAGE = "source:markets"
YAHOO = "https://query1.finance.yahoo.com/v8/finance/chart/"
# Yahoo answers 429 to full browser user agents but not to this one.
YAHOO_HEADERS = {"User-Agent": "Mozilla/5.0"}


def pct(new, old):
    return round((new / old - 1) * 100, 2) if old else None


def quote(market):
    try:
        # Yahoo rate-limits bursts (HTTP 429): stay sequential-ish and back off.
        time.sleep(0.3)
        data = http_json(YAHOO + market["symbol"], params={"range": "1y", "interval": "1d"}, headers=YAHOO_HEADERS, timeout=20, retries=4)
        result = data["chart"]["result"][0]
    except Exception as error:  # noqa: BLE001
        log(STAGE, f"{market['symbol']}: {error}")
        return None
    closes = [c for c in result["indicators"]["quote"][0].get("close", []) if c is not None]
    meta = result["meta"]
    if len(closes) < 2:
        return None
    last = meta.get("regularMarketPrice") or closes[-1]
    high = max(meta.get("fiftyTwoWeekHigh") or 0, *closes)
    low = min(meta.get("fiftyTwoWeekLow") or last, *closes)
    at = lambda back: closes[-back - 1] if len(closes) > back else closes[0]  # noqa: E731
    return {
        "symbol": market["symbol"],
        "name": market["name"],
        "last": round(last, 4),
        "currency": meta.get("currency", ""),
        "chg_1d": pct(last, closes[-2]),
        "chg_1w": pct(last, at(5)),
        "chg_1m": pct(last, at(21)),
        "chg_1y": pct(last, closes[0]),
        "from_52w_high": pct(last, high),
        "from_52w_low": pct(last, low),
        "investable": market.get("signal", True),
    }


def fred(series, api_key):
    try:
        data = http_json(
            "https://api.stlouisfed.org/fred/series/observations",
            params={"series_id": series["id"], "units": series.get("units", "lin"), "api_key": api_key, "file_type": "json", "sort_order": "desc", "limit": "10"},
        )
    except Exception as error:  # noqa: BLE001
        log(STAGE, f"FRED {series['id']}: {error}")
        return None
    observations = [o for o in data.get("observations", []) if o.get("value") not in (".", None)]
    if len(observations) < 2:
        return None
    latest, previous = observations[0], observations[1]
    return {
        "id": series["id"],
        "label": series["label"],
        "latest": float(latest["value"]),
        "date": latest["date"],
        "previous": float(previous["value"]),
        "change": round(float(latest["value"]) - float(previous["value"]), 3),
    }


def fear_greed():
    try:
        data = http_json("https://api.alternative.me/fng/", params={"limit": "8"})["data"]
    except Exception as error:  # noqa: BLE001
        log(STAGE, f"fear & greed: {error}")
        return None
    return {
        "value": int(data[0]["value"]),
        "label": data[0]["value_classification"],
        "yesterday": int(data[1]["value"]) if len(data) > 1 else None,
        "week_ago": int(data[7]["value"]) if len(data) > 7 else None,
    }


def earnings(symbols, api_key, days):
    today = now_utc().date()
    try:
        data = http_json(
            "https://finnhub.io/api/v1/calendar/earnings",
            params={"from": today.isoformat(), "to": (today + timedelta(days=days)).isoformat(), "token": api_key},
        )
    except Exception as error:  # noqa: BLE001
        log(STAGE, f"earnings: {error}")
        return []
    wanted = set(symbols)
    rows = [r for r in data.get("earningsCalendar", []) if r.get("symbol") in wanted]
    return sorted(({"symbol": r["symbol"], "date": r["date"], "hour": r.get("hour", "")} for r in rows), key=lambda r: r["date"])


def signed(value):
    return f"{'up' if value >= 0 else 'down'} {abs(value):.1f}%"


def highlights(config, groups, quotes, macro, fng, upcoming):
    weekly = config.get("mode") == "weekly"
    window, threshold = ("chg_1w", float(config.get("moveThreshold1w", 7.0))) if weekly else ("chg_1d", float(config.get("moveThreshold1d", 3.0)))
    period = "this week" if weekly else "today"
    lines = []

    def add(tag, text):
        lines.append({"tag": tag, "text": text})

    first_group = groups[0] if groups else None
    if first_group:
        parts = [f"{q['name']} {signed(q[window])}" for m in first_group["markets"] if (q := quotes.get(m["symbol"])) and q[window] is not None]
        if parts:
            add("market", f"{first_group['title']} {period}: " + "; ".join(parts) + ".")

    group_of = {}
    for group in groups:
        for market in group["markets"]:
            group_of.setdefault(market["symbol"], group["title"])

    movers = sorted((q for q in quotes.values() if q["investable"] and q[window] is not None and abs(q[window]) >= threshold), key=lambda q: -abs(q[window]))
    for q in movers[:10]:
        add("market", f"Big move: {q['name']} ({q['symbol']}, {group_of.get(q['symbol'], '')}) {signed(q[window])} {period}; {q['from_52w_high']:.1f}% from 52-week high.")

    for q in quotes.values():
        if q["investable"] and q["from_52w_high"] is not None and q["from_52w_high"] > -1.0:
            add("market", f"At/near 52-week high: {q['name']} ({q['symbol']}), {signed(q['chg_1y'])} over 1 year.")
        elif q["investable"] and q["from_52w_high"] is not None and q["from_52w_high"] <= -30.0:
            add("market", f"Deep drawdown: {q['name']} ({q['symbol']}) {q['from_52w_high']:.1f}% below 52-week high.")

    vix = quotes.get("^VIX")
    if vix:
        mood = "high stress" if vix["last"] >= 30 else "elevated fear" if vix["last"] >= 20 else "calm" if vix["last"] < 15 else "normal"
        add("sentiment", f"VIX at {vix['last']:.1f} ({mood}), {signed(vix[window])} {period}.")

    if fng:
        extreme = " (extreme)" if fng["value"] <= 25 or fng["value"] >= 75 else ""
        add("sentiment", f"Crypto Fear & Greed index {fng['value']} = {fng['label']}{extreme}; yesterday {fng['yesterday']}, a week ago {fng['week_ago']}.")

    for series in macro:
        add("macro", f"{series['label']}: {series['latest']:.2f} as of {series['date']} (previous {series['previous']:.2f}, change {series['change']:+.2f}).")
        if series["id"] == "T10Y2Y" and series["latest"] < 0:
            add("macro", "Yield curve 10Y-2Y is inverted (historically a recession warning).")

    for row in upcoming[:12]:
        when = {"bmo": " before open", "amc": " after close"}.get(row["hour"], "")
        add("earnings", f"Upcoming earnings: {row['symbol']} on {row['date']}{when}.")
    return lines


def main():
    config = json.load(sys.stdin)
    groups = config.get("groups", [])
    unique = {}
    for group in groups:
        for market in group["markets"]:
            unique.setdefault(market["symbol"], market)

    with ThreadPoolExecutor(max_workers=2) as pool:
        quotes = {q["symbol"]: q for q in pool.map(quote, unique.values()) if q}

    fred_key = os.environ.get("FRED_API_KEY", "")
    macro = [s for s in (fred(series, fred_key) for series in config.get("fredSeries", [])) if s] if fred_key else []
    fng = fear_greed() if config.get("fearGreed", True) else None
    finnhub_key = os.environ.get("FINNHUB_API_KEY", "")
    days = 14 if config.get("mode") == "weekly" else 7
    upcoming = earnings(config.get("earningsSymbols", []), finnhub_key, days) if finnhub_key and config.get("earningsSymbols") else []

    facts = {
        "source": config["key"],
        "title": config.get("title", "Markets and macro"),
        "asof": iso(now_utc()),
        "highlights": highlights(config, groups, quotes, macro, fng, upcoming),
        "sections": [
            {"title": group["title"], "rows": [quotes[m["symbol"]] for m in group["markets"] if m["symbol"] in quotes]} for group in groups
        ]
        + ([{"title": "Macro (FRED)", "rows": macro}] if macro else [])
        + ([{"title": "Upcoming earnings", "rows": upcoming}] if upcoming else []),
        "fear_greed": fng,
    }
    json.dump(facts, sys.stdout, ensure_ascii=False)
    log(STAGE, f"{len(quotes)}/{len(unique)} quotes, {len(macro)} FRED series, {len(facts['highlights'])} highlights")


if __name__ == "__main__":
    main()
