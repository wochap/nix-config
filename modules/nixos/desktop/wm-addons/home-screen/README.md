# home-screen

Markets dashboard built on [Glance](https://github.com/glanceapp/glance), served behind `web-gate` at `home-screen` (public `18080` → backend `18081`, lazy-started).

## Stack

- **Glance** (`services.glance`): pages, columns, widgets, generated entirely from Nix.
- **Go html/template** files in `widgets/templates/` power the `custom-api` widgets. Nix runs a `@VAR@` substitution pass over them before they reach Glance.
- **sops-nix**: optional API keys from `secrets-sops/personal.yaml`, injected via the `glance.env` env file.
- **systemd hardening**: `strictNetworkService` plus extra restrictions on `glance.service`.

## Layout

```
default.nix          module: options, pages/columns, sops, systemd
markets.nix          watchlist groups (symbols); shared by both pages
widgets/default.nix  widget builders + template preprocessing
widgets/rss.nix      RSS widgets
widgets/fred.nix     FRED series list
widgets/glossary.nix tooltip texts -> @TIP_<NAME>@
widgets/templates/   Go templates + shared styles.css
```

## How it works

- **Markets page**: three columns of built-in `markets` widgets (one per watchlist group), RSS, Fear & Greed, plus optional FRED rates and an earnings calendar.
- **Charts page**: one `custom-api` card per symbol across `chartGroups` (deduplicated, first group wins). Each card pulls 1y of daily Yahoo data and renders 1M/3M/6M/1Y charts, technical signals and a buy-zone verdict. US equities with Finnhub enabled also get valuation, analyst ratings and news.
- **Template vars**: `@TIP_*@` (glossary), `@FINNHUB_TOKEN@`, `@FRED_TOKEN@`. Token vars come out empty when their provider is disabled, because Glance won't start if a `${VAR}` is unset.
- **`data` option** (read-only): exposes market groups, RSS widgets, FRED series and earnings symbols so other modules (e.g. the briefing podcast) can reuse them.

## Providers

| Provider | Used for | Key |
|---|---|---|
| Yahoo Finance | `markets` widgets, chart cards | none |
| Finnhub | fundamentals, analysts, news, earnings | `personal-finnhub-api-key` (`finnhub.enable`) |
| FRED | Macro Rates | `personal-fred-api-key` (`fred.enable`) |
| CNN / alternative.me | Fear & Greed | none |
| RSS feeds | news widgets | none |

Before enabling `finnhub`/`fred`, add the key to `personal.yaml`. Otherwise sops activation fails.

## Adding sources

### Symbols (Yahoo, optionally Finnhub)

Add an entry to a group in `markets.nix`:

```nix
{ symbol = "TXN"; name = "Texas Instruments"; }
```

- Use Yahoo symbol syntax: `^VIX`, `GC=F`, `PEN=X`, `BTC-USD`, `000660.KS`.
- `fundamentals = false;` for US ETFs (Finnhub has no P/E or earnings for them). Non-US and special symbols are skipped automatically.
- `signal = false;` hides the buy-zone verdict (indexes, yields, FX).

**New group**: add `myGroup = { title = "..."; markets = [ ... ]; };` to `markets.nix`. Then list it in `chartGroups` (`default.nix`) for the Charts page and briefing, and place `(mkMarketsWidget markets.myGroup)` in a Markets page column.

### RSS

Add `{ url = "..."; title = "..."; }` to `feeds` of a widget in `widgets/rss.nix`. For a new widget, add an attr there and reference it as `widgets.rss.<name>` in a column. New widgets reach `data.rssWidgets` automatically.

### FRED

Append to `widgets/fred.nix`:

```nix
{ id = "PAYEMS"; label = "Nonfarm payrolls"; units = "pc1"; tip = "payrolls"; }
```

`units` defaults to `lin` (`pc1` = YoY %). `tip` must be a key in `widgets/glossary.nix`, so add it there too.

### Finnhub

No per-symbol config. Any US equity in `markets.nix` is covered. New endpoints go in the templates via `newRequest ... | withParameter "token" "@FINNHUB_TOKEN@"`. Guard them with the `fundamentals` option or `finnhub` flag.

### New provider / custom widget

1. Add a template to `widgets/templates/` and a builder in `widgets/default.nix` that calls `render { "@MY_VAR@" = ...; } "my.html"`.
2. If it needs a key: add the secret + `*.enable` option in `default.nix`, a `KEY=` line in the `glance.env` template, and a `@MY_TOKEN@` global var (emitted only when enabled).
3. Put tooltips in `glossary.nix` and use them as `@TIP_<NAME>@`.
4. Include `widgets.styles` once per page if the widget uses the shared CSS.
