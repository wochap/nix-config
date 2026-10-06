# Briefing

A daily and weekly audio news briefing, built from local sources and published to
Syncthing for the phone.

```
sources ──► collect ──► dedup ──► rank ──► enrich ──► write ──► tts ──► package ──► publish
(adapters)  items+facts  ledger    LLM      article-   LLM per   Super-   MP3 +       ~/Sync/podcasts
                                   score +  scrape     chapter   tonic    ID3 CHAP
                                   cluster  (top N)
```

Enable it with `_custom.services.ai.briefing.enable = true;`. It needs OmniRoute,
Supertonic, article (for `article-scrape`) and the home-screen module.

## Commands

```sh
briefing                          # today's daily episode (resumes a failed run)
briefing --mode weekly
briefing --from write             # rerun from a stage (collect dedup rank enrich write tts package publish)
briefing --until rank             # stop after a stage (inspect ~/.local/state/briefing/runs/<date>-<mode>/)
briefing --date 2026-10-02
briefing ledger search nvidia     # which episodes already covered something
briefing ledger rebuild           # rebuild the ledger from ~/Sync/podcasts/*/stories.jsonl
systemctl --user start briefing-daily
journalctl --user -u briefing-daily
```

Each stage is its own CLI (`briefing-collect`, `briefing-rank`, ...). Use `--help` on any of them.

Timers: daily 06:30, weekly Sunday 08:00 (`Persistent`, so a run missed while
the computer was off runs at the next boot). Change them with
`briefing.daily.onCalendar` / `briefing.weekly.onCalendar`, or set them to `null`.

## Output

`~/Sync/podcasts/<date>-<mode>/`:

| File | Content |
|---|---|
| `<date>-<mode>.mp3` | Episode with chapters |
| `script.md` | Script with the stories behind each chapter |
| `chapters.json` | Chapter texts |
| `stories.jsonl` | Ranked stories (score, topic, sources, article text, `used`) |
| `sources.jsonl` | Every collected item |
| `facts.json` | Computed market and macro numbers |
| `manifest.json`, `collect-report.json` | Run metadata and per-source status |

`~/Sync/podcasts/listen/` gets a flat copy of the latest MP3s (kept for 14 days).
In AntennaPod, use **Add podcast → Add local folder** on that folder; local folders
are not scanned recursively.

The dedup ledger (`~/.local/state/briefing/ledger.db`) stays out of Sync so that
Syncthing never sees a SQLite file change on two devices. It stores URL and title
hashes of every story used, per mode, and is rebuildable from `stories.jsonl`.

## Sources (adapter pattern)

`briefing.sources` is a registry. Each entry is piped as JSON on stdin to the
executable `briefing-source-<adapter>`. Common fields:

- `adapter`: which executable to run.
- `kind`: `items` (news, JSON lines) or `facts` (one JSON object).
- `modes`: `[ "daily" ]`, `[ "weekly" ]` or both.
- `enable`: set to `false` to turn the source off.
- `timeout`: seconds, 600 by default.

A source that fails is reported in `collect-report.json` and the episode is still made.

Built-in sources:

| Key | Adapter | Notes |
|---|---|---|
| `newsboat` | `newsboat` | Runs `newsboat -x reload` first; if the TUI holds the lock, it uses the cache. `tags` selects feeds by the tag in `urls`. |
| `glance-news` | `rss` | The RSS widgets of the home-screen. |
| `markets` | `markets` | Watchlist groups, FRED series and earnings from the home-screen. |
| `past-dailies` | `episodes` | Weekly only: stories from the last 7 daily episodes. |

The market, RSS and FRED lists come from `_custom.desktop.home-screen.data`.
If you add or remove a dashboard section, the briefing follows on the next rebuild.

Examples:

```nix
_custom.services.ai.briefing.sources = {
  newsboat.tags = [ "Tech" "GitHub" "X" "YouTube" ];
  glance-news.enable = false;

  # Any CLI that prints JSON
  my-scraper = {
    adapter = "command";
    kind = "items";
    modes = [ "daily" ];
    command = "my-scraper --json";
    jq = ".[] | {title, url, snippet: .summary, published: .date}";
  };

  # A JSON endpoint
  hn-best = {
    adapter = "http-json";
    kind = "items";
    url = "https://hacker-news.firebaseio.com/v0/beststories.json";
    jq = "...";
  };

  # A file another tool drops
  notes = {
    adapter = "file-json";
    kind = "facts";
    path = "~/Sync/briefing-notes.json";
  };
};
```

Item fields are `title` (required), `url`, `section`, `feed`, `published` (ISO 8601)
and `snippet`; other fields are kept. Facts are
`{title, highlights: [string | {tag, text}], sections: [{title, rows}]}`.
A chapter uses facts through its `facts` list (`"source"` or `"source:tag"`).

To write a new adapter type, add a script under `briefing/adapters/` and list it in
`builtinAdapters` in `default.nix`. You can also pass any package that provides
`bin/briefing-source-<name>` through `briefing.extraAdapters.<name>`.

## Tuning

- `interests.md`: listener profile, used by the rank and write prompts.
- `briefing.chapters`: chapter order and descriptions. `kind = "stories"` chapters are
  also the topics the ranker assigns. The `kind = "hype"` chapter collects stories
  flagged as hype.
- `briefing.{daily,weekly}`: `maxStories`, `enrichTop`, `threshold`, `words` (about 150
  per minute), `introWords`, `outroWords`.
- `briefing.{model,voice,speed,show,cover}`.
- `prompts/*.md`: ranking, clustering, chapter and intro/outro prompts.

Numbers in the script come from `facts.json` (computed in `adapters/markets.py`).
The chapter prompt tells the model not to use any number that is not in the facts
or the stories.
