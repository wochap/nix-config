{
  config,
  pkgs,
  lib,
  ...
}:

let
  ai = config._custom.services.ai;
  cfg = ai.briefing;
  inherit (config._custom.globals) userName;
  inherit (pkgs._custom) wochap-ssc;
  homeScreen = config._custom.desktop.home-screen;
  proxies = config._custom.services.web-gate.proxies;
  host = "http://${wochap-ssc.meta.address}";
  # Secrets the stages read from the environment, through briefing.env.
  useJev = cfg.scorer == "jev";
  needsEnvFile = homeScreen.finnhub.enable || homeScreen.fred.enable || useJev;

  python = pkgs.python3.withPackages (pythonPackages: [
    pythonPackages.feedparser
    pythonPackages.numpy
  ]);
  src = lib.fileset.toSource {
    root = ./.;
    fileset = ./briefing;
  };

  # One executable per stage/adapter; all share the `briefing` Python package.
  mkPythonBin =
    name: module:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        python
        pkgs.jq
        pkgs.ffmpeg
      ];
      runtimeEnv = {
        PYTHONPATH = src;
        SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
      };
      text = ''exec python3 -m briefing.${module} "$@"'';
    };

  stages = lib.mapAttrsToList mkPythonBin {
    briefing-collect = "collect";
    briefing-ledger = "ledger";
    briefing-rank = "rank";
    briefing-enrich = "enrich";
    briefing-write = "write";
    briefing-tts = "tts";
    briefing-package = "package";
  };

  builtinAdapters = lib.mapAttrs (name: module: mkPythonBin "briefing-source-${name}" module) {
    newsboat = "adapters.newsboat";
    rss = "adapters.rss";
    markets = "adapters.markets";
    episodes = "adapters.episodes";
    command = "adapters.command";
    http-json = "adapters.http_json";
    file-json = "adapters.file_json";
  };
  adapters = lib.attrValues (builtinAdapters // cfg.extraAdapters);

  registry = pkgs.writeText "briefing-sources.json" (
    builtins.toJSON (lib.filterAttrs (_: source: source.enable or true) cfg.sources)
  );

  profile = pkgs.writeText "briefing-profile.json" (
    builtins.toJSON {
      inherit (cfg) show chapters similarity;
      interests = builtins.readFile cfg.interestsFile;
      daily = cfg.daily // {
        onCalendar = null;
      };
      weekly = cfg.weekly // {
        onCalendar = null;
      };
    }
  );

  briefing = pkgs.writeShellApplication {
    name = "briefing";
    runtimeInputs =
      stages
      ++ adapters
      ++ (with pkgs; [
        coreutils
        findutils
        gawk
        jq
        ffmpeg
        libnotify
      ]);
    runtimeEnv = {
      BRIEFING_REGISTRY = registry;
      BRIEFING_PROFILE = profile;
      BRIEFING_PROMPTS = ./prompts;
    };
    # Defaults overridable from the environment (the systemd units set them).
    text = ''
      : "''${BRIEFING_STATE_DIR:=''${XDG_STATE_HOME:-$HOME/.local/state}/briefing}"
      : "''${BRIEFING_OUT_DIR:=${cfg.outDir}}"
      : "''${BRIEFING_MODEL:=${cfg.model}}"
      : "''${BRIEFING_VOICE:=${cfg.voice}}"
      : "''${BRIEFING_SPEED:=${toString cfg.speed}}"
      : "''${SUPERTONIC_URL:=https://supertonic.${wochap-ssc.meta.domain}}"
      : "''${BRIEFING_LISTEN_DIR=${lib.optionalString (cfg.listenDir != null) cfg.listenDir}}"
      : "''${BRIEFING_SCORER:=${cfg.scorer}}"
      : "''${BRIEFING_EMBED_URL:=http://127.0.0.1:11434/v1}"
      : "''${BRIEFING_EMBED_MODEL:=${ai.ollamaEmbeddingModel}}"
      : "''${BRIEFING_RERANK_URL=${lib.optionalString ai.reranker.enable "${host}:${toString proxies.reranker.publicPort}/v1"}}"
      : "''${BRIEFING_RERANK_MODEL:=${ai.reranker.model}}"
      : "''${BRIEFING_JEV_URL:=https://api.typesafe.ai/v1}"
      : "''${BRIEFING_SEARXNG_URL:=${host}:${toString proxies.searxng.publicPort}}"
      : "''${BRIEFING_FIRECRAWL_URL:=${host}:${toString proxies.firecrawl.publicPort}/v1}"
      export BRIEFING_STATE_DIR BRIEFING_OUT_DIR BRIEFING_MODEL BRIEFING_VOICE BRIEFING_SPEED SUPERTONIC_URL BRIEFING_PROMPTS
      export BRIEFING_LISTEN_DIR BRIEFING_SCORER BRIEFING_EMBED_URL BRIEFING_EMBED_MODEL BRIEFING_RERANK_URL
      export BRIEFING_RERANK_MODEL BRIEFING_JEV_URL BRIEFING_SEARXNG_URL BRIEFING_FIRECRAWL_URL
    ''
    + builtins.readFile ./briefing.sh;
  };

  modeOptions = mode: defaults: {
    onCalendar = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = defaults.onCalendar;
      description = "systemd OnCalendar for the ${mode} episode; null disables the timer.";
    };
    maxStories = lib.mkOption {
      type = lib.types.int;
      default = defaults.maxStories;
    };
    keep = lib.mkOption {
      type = lib.types.ints.positive;
      default = defaults.keep;
      description = "How many ${mode} episodes to keep in outDir and listenDir; older ones are deleted.";
    };
    minStories = lib.mkOption {
      type = lib.types.int;
      default = 4;
    };
    enrichTop = lib.mkOption {
      type = lib.types.int;
      default = defaults.enrichTop;
      description = "How many top stories get their full article scraped (Firecrawl).";
    };
    prefilter = lib.mkOption {
      type = lib.types.int;
      default = defaults.prefilter;
      description = "How many items closest to a chapter topic (embeddings) go on to scoring.";
    };
    corroborateTop = lib.mkOption {
      type = lib.types.int;
      default = defaults.corroborateTop;
      description = "How many top single-source stories get extra sources from a SearXNG search.";
    };
    dedupDays = lib.mkOption {
      type = lib.types.ints.positive;
      default = defaults.dedupDays;
      description = "How far back the embedding dedup compares against stories already told.";
    };
    threshold = lib.mkOption {
      type = lib.types.float;
      default = 0.6;
      description = "Minimum relevance score (0-1) for a story.";
    };
    fallbackScore = lib.mkOption {
      type = lib.types.float;
      default = 0.3;
      description = "Score for items the LLM did not score.";
    };
    words = lib.mkOption {
      type = lib.types.int;
      default = defaults.words;
      description = "Target script length (~150 spoken words per minute).";
    };
    introWords = lib.mkOption {
      type = lib.types.int;
      default = defaults.introWords;
    };
    outroWords = lib.mkOption {
      type = lib.types.int;
      default = defaults.outroWords;
    };
  };

  # Every field gets mkDefault, so hosts can override single fields such as
  # `sources.newsboat.tags` or `sources.glance-news.enable = false`.
  defaultSources = {
    newsboat = {
      adapter = "newsboat";
      kind = "items";
      modes = [ "daily" ];
      tags = [
        "Tech"
        "GitHub"
        "X"
      ];
      since = "24h";
    };
    glance-news = {
      adapter = "rss";
      kind = "items";
      modes = [ "daily" ];
      since = "24h";
      feeds = lib.concatMap (
        widget: map (feed: feed // { section = widget.title; }) widget.feeds
      ) homeScreen.data.rssWidgets;
    };
    markets = {
      adapter = "markets";
      kind = "facts";
      modes = [
        "daily"
        "weekly"
      ];
      title = "Markets and macro";
      groups = map (group: {
        inherit (group) title;
        markets = map (market: {
          inherit (market) symbol name;
          signal = market.signal or true;
        }) group.markets;
      }) homeScreen.data.marketGroups;
      fredSeries = map (series: {
        inherit (series) id label;
        units = series.units or "lin";
      }) homeScreen.data.fredSeries;
      inherit (homeScreen.data) earningsSymbols;
      fearGreed = true;
    };
    past-dailies = {
      adapter = "episodes";
      kind = "items";
      modes = [ "weekly" ];
      sourceMode = "daily";
      days = 7;
    };
  };
in
{
  options._custom.services.ai.briefing = {
    enable = lib.mkEnableOption "daily/weekly news briefing podcast";

    show = lib.mkOption {
      type = lib.types.str;
      default = "Wochap Briefing";
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "desktop-free";
      description = "OmniRoute model or combo used for ranking and writing.";
    };

    voice = lib.mkOption {
      type = lib.types.str;
      default = "M1";
      description = "Supertonic voice (M1-M5, F1-F5 or an imported one).";
    };

    speed = lib.mkOption {
      type = lib.types.float;
      default = 1.05;
    };

    outDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/${userName}/Sync/podcasts";
      description = "Published episodes land in <outDir>/<date>-<mode>/.";
    };

    listenDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "${cfg.outDir}/listen";
      description = ''
        Flat folder that also gets each episode MP3 (pruned like outDir, see <mode>.keep).
        Point AntennaPod's "add local folder" here; it does not scan subfolders.
      '';
    };

    cover = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional cover image embedded in every episode.";
    };

    scorer = lib.mkOption {
      type = lib.types.enum [
        "jev"
        "rerank"
      ];
      default = "jev";
      description = ''
        Relevance scorer. "jev" sends item titles and snippets (public news)
        to TypeSafe Jev with personal-typesafe-api-key from personal.yaml;
        "rerank" uses the local reranker. The LLM then reviews only the top
        `maxStories * 3` items, and scores everything itself if the scorer fails.
      '';
    };

    similarity = {
      dedup = lib.mkOption {
        type = lib.types.float;
        default = 0.88;
        description = "Embedding cosine at which a new item counts as a story already told.";
      };
      cluster = lib.mkOption {
        type = lib.types.float;
        default = 0.82;
        description = "Embedding cosine at which items are grouped into one story.";
      };
      corroborate = lib.mkOption {
        type = lib.types.float;
        default = 0.75;
        description = "Embedding cosine a search result needs to join a story's sources.";
      };
    };

    interestsFile = lib.mkOption {
      type = lib.types.path;
      default = ./interests.md;
      description = "Listener profile used by ranking and writing prompts.";
    };

    sources = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = { };
      description = ''
        Source registry. Each entry is piped as JSON to `briefing-source-<adapter>`.
        Common fields: adapter, kind ("items" or "facts"), modes, enable.
        See README.md for adapter-specific fields.
      '';
    };

    extraAdapters = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = { };
      description = "Extra adapters; each package must provide bin/briefing-source-<name>.";
    };

    chapters = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
      description = ''
        Chapter order. kind "stories" chapters are also the topics stories are
        sorted into; the kind "hype" chapter collects hype-flagged stories.
        `facts` lists fact sources as "source" or "source:tag".
      '';
      default = [
        {
          key = "markets";
          kind = "stories";
          title = "Markets pulse";
          description = "Stock market moves and why: indexes, big movers, crashes, rallies, earnings, company news that moves stocks.";
          facts = [
            "markets:market"
            "markets:sentiment"
            "markets:earnings"
          ];
        }
        {
          key = "macro";
          kind = "stories";
          title = "Economy and macro";
          description = "How the economy is doing: central banks, rates, inflation, jobs, recession signals, trade, regulation (Fed, SEC).";
          facts = [ "markets:macro" ];
        }
        {
          key = "ai";
          kind = "stories";
          title = "AI models and labs";
          description = "New AI model releases, benchmarks, AI lab news, AI chips and compute deals.";
          facts = [ ];
        }
        {
          key = "tech";
          kind = "stories";
          title = "Tech and breakthroughs";
          description = "Notable technology news, developer tools, open source, trending repositories, genuinely revolutionary research.";
          facts = [ ];
        }
        {
          key = "hype";
          kind = "hype";
          title = "Hype check";
          description = "Separate signal from noise: what is overhyped or overextended, and what is under-appreciated.";
          facts = [ ];
        }
      ];
    };

    daily = modeOptions "daily" {
      onCalendar = "*-*-* 06:30:00";
      keep = 14;
      maxStories = 14;
      enrichTop = 12;
      prefilter = 120;
      corroborateTop = 6;
      dedupDays = 10;
      words = 1500;
      introWords = 110;
      outroWords = 140;
    };

    weekly = modeOptions "weekly" {
      onCalendar = "Sun *-*-* 08:00:00";
      keep = 3;
      maxStories = 24;
      enrichTop = 10;
      prefilter = 160;
      corroborateTop = 8;
      dedupDays = 28;
      words = 3800;
      introWords = 160;
      outroWords = 260;
    };
  };

  config = lib.mkIf (ai.enable && cfg.enable) {
    assertions = [
      {
        assertion = ai.enableOmniRoute && ai.enableSupertonic && ai.enableFirecrawl;
        message = "_custom.services.ai.briefing requires enableOmniRoute, enableSupertonic and enableFirecrawl.";
      }
      {
        assertion = cfg.scorer != "rerank" || ai.reranker.enable;
        message = ''_custom.services.ai.briefing.scorer = "rerank" needs _custom.services.ai.reranker.enable; use "jev" otherwise.'';
      }
      {
        assertion = config._custom.services.searxng.enable;
        message = "_custom.services.ai.briefing corroborates stories through _custom.services.searxng.";
      }
      {
        assertion = homeScreen.enable;
        message = "_custom.services.ai.briefing reads its market/news sources from _custom.desktop.home-screen.";
      }
    ];

    _custom.services.ai.briefing.sources = lib.mapAttrs (
      _: lib.mapAttrs (_: lib.mkDefault)
    ) defaultSources;

    # Only rendered into the briefing.env template, so it keeps sops' default owner.
    sops.secrets.personal-typesafe-api-key = lib.mkIf useJev {
      sopsFile = ../../../../../secrets-sops/personal.yaml;
    };

    # The market API key secrets are declared by the home-screen module.
    sops.templates."briefing.env" = lib.mkIf needsEnvFile {
      mode = "0400";
      owner = userName;
      content =
        lib.optionalString homeScreen.finnhub.enable ''
          FINNHUB_API_KEY=${config.sops.placeholder.personal-finnhub-api-key}
        ''
        + lib.optionalString homeScreen.fred.enable ''
          FRED_API_KEY=${config.sops.placeholder.personal-fred-api-key}
        ''
        + lib.optionalString useJev ''
          JEV_API_KEY=${config.sops.placeholder.personal-typesafe-api-key}
        '';
    };

    _custom.hm =
      let
        mkService = mode: {
          Unit.Description = "Generate the ${mode} briefing podcast";
          Service = {
            Type = "oneshot";
            # Timers catch up right after resume, before the network is back.
            ExecStartPre = lib.optional config.networking.networkmanager.enable "${config.networking.networkmanager.package}/bin/nm-online -s -q -t 120";
            ExecStart = "${lib.getExe briefing} --mode ${mode}";
            StateDirectory = "briefing";
            Environment = [
              "BRIEFING_STATE_DIR=%S/briefing"
              # omniroute-chat is a system package, newsboat a user one.
              "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/${userName}/bin"
            ]
            ++ lib.optional (cfg.cover != null) "BRIEFING_COVER=${cfg.cover}";
            EnvironmentFile = lib.optional needsEnvFile config.sops.templates."briefing.env".path;
            TimeoutStartSec = "2h";
            Nice = 10;
          };
        };
        mkTimer = mode: onCalendar: {
          Unit.Description = "Schedule the ${mode} briefing podcast";
          Timer = {
            OnCalendar = onCalendar;
            Persistent = true;
            Unit = "briefing-${mode}.service";
          };
          Install.WantedBy = [ "timers.target" ];
        };
      in
      {
        home.packages = [ briefing ] ++ stages ++ adapters;

        systemd.user.services = {
          briefing-daily = mkService "daily";
          briefing-weekly = mkService "weekly";
        };

        systemd.user.timers =
          lib.optionalAttrs (cfg.daily.onCalendar != null) {
            briefing-daily = mkTimer "daily" cfg.daily.onCalendar;
          }
          // lib.optionalAttrs (cfg.weekly.onCalendar != null) {
            briefing-weekly = mkTimer "weekly" cfg.weekly.onCalendar;
          };
      };
  };
}
