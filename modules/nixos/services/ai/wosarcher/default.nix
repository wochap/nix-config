{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  wcfg = cfg.wosarcher;
  inherit (pkgs._custom) wochap-ssc;
  source = inputs.wosarcher;
  revision = source.rev or (throw "The wosarcher flake input must be locked to a Git revision");
  ociBackend = config.virtualisation.oci-containers.backend;
  toml = pkgs.formats.toml { };
  # Total context window and largest completion per model (../model-presets.nix).
  models = import ../model-presets.nix { inherit lib; };

  serviceName = "${ociBackend}-wosarcher";
  # The image runs as this user (see the Dockerfile's useradd).
  uid = 10001;
  gid = 10001;
  dataDir = "/var/lib/wosarcher";
  profilesDir = "${dataDir}/config/wosarcher/profiles";

  proxy = config._custom.services.web-proxies.wosarcher;
  searxProxy = config._custom.services.web-proxies.searxng;
  omniRouteProxy = config._custom.services.web-proxies.omniroute;
  firecrawlPublicPort = lib.attrByPath [
    "firecrawl"
    "publicPort"
  ] 20900 config._custom.services.web-proxies;
  rerankerProxy = config._custom.services.web-proxies.reranker;
  host = "http://${wochap-ssc.meta.address}";

  # Every provider goes through the host's proxies, so the container needs
  # --network=host. The reranker is reached through its lazy socket proxy: the
  # first rerank starts llama-server again after the idle watchdog stopped it.
  commonProfile = {
    run.gpu_policy = "shared";
    search = {
      provider = "searxng";
      base_url = "${host}:${toString searxProxy.publicPort}";
    };
    fetch = {
      provider = "firecrawl";
      base_url = "${host}:${toString firecrawlPublicPort}/v1";
    };
  };

  # The llm and research blocks for one entry of `llms`. context_window is the
  # model's total window (prompt plus completion): wosarcher subtracts the
  # prompt reserve and the output allowance itself to size the passages. As in
  # gpt-researcher, a completion never claims more than half the window.
  llmSettings =
    llm:
    let
      m = models.resolve "wosarcher" llm.preset;
    in
    {
      llm = {
        provider = "llm";
        base_url = "${host}:${toString omniRouteProxy.publicPort}/v1";
        inherit (llm) model timeout;
        context_window = m.contextTokens;
        max_output_tokens = lib.min models.maxOutputCap (lib.min m.maxOutputTokens (m.contextTokens / 2));
      };
    }
    // lib.optionalAttrs (llm.research != { }) { inherit (llm) research; };

  embeddingsPrefilter = {
    provider = "embeddings";
    base_url = "http://127.0.0.1:11434/v1";
    model = cfg.ollamaEmbeddingModel;
    device = "local:gpu0";
  };

  # Without the shared reranker this falls back to BM25 scoring.
  rerankScore =
    if cfg.reranker.enable then
      {
        provider = "rerank";
        base_url = "${host}:${toString rerankerProxy.publicPort}/v1";
        model = cfg.reranker.model;
        device = "local:gpu0";
        # Covers llama-server loading the GGUF on the first request.
        timeout = 120;
      }
    else
      { provider = "bm25"; };

  # TypeSafe Jev: a cloud scorer with calibrated 0-3 usefulness scores. It
  # sends every chunk to api.typesafe.ai and needs an API key. In a replay of
  # 9 questions it was judged at least as precise as the local reranker, with
  # a 2-4 s score stage instead of 26-40 s on the GPU.
  jevScore = {
    provider = "jev";
    base_url = "https://api.typesafe.ai/v1";
    concurrency = 16;
    timeout = 120;
  };

  # How passages are picked; each is paired with every entry of `llms`.
  scorerVariants = {
    embeddings-rerank = commonProfile // {
      prefilter = embeddingsPrefilter;
      score = rerankScore;
    };
  }
  // lib.optionalAttrs wcfg.jev.enable {
    embeddings-jev = commonProfile // {
      prefilter = embeddingsPrefilter;
      score = jevScore;
    };
    # No embedding step: BM25 picks the candidates Jev scores.
    bm25-jev = commonProfile // {
      prefilter.provider = "bm25";
      score = jevScore;
    };
    # Coverage over speed (not yet evaluated): Jev scores twice the
    # candidates, keeps only "partly answers" (2.0 of 3) and above, and up to
    # 25 per sub-query, which fills more of the writer's context budget. Depth
    # presets set score.top_k themselves and win over a profile, so use it
    # with Standard depth and add rounds per run (--rounds 3, or Rounds in the
    # web's Custom depth with Passages per query 25).
    bm25-jev-wide = commonProfile // {
      prefilter = {
        provider = "bm25";
        top_k = 100;
      };
      score = jevScore // {
        min_score = 2.0;
        top_k = 25;
      };
    };
  };

  # Every scorer variant once per LLM: the `defaultLlm` keeps the plain
  # variant name (so WOSARCHER_PROFILE values keep working), every other LLM
  # gets a "-<llm>" suffix, for example bm25-jev-free.
  generatedProfiles = lib.concatMapAttrs (
    llmName: llm:
    lib.mapAttrs' (
      variant: settings:
      lib.nameValuePair (if llmName == wcfg.defaultLlm then variant else "${variant}-${llmName}") (
        settings // llmSettings llm
      )
    ) scorerVariants
  ) wcfg.llms;

  profileFiles = lib.mapAttrs (
    name: settings: toml.generate "wosarcher-${name}.toml" settings
  ) wcfg.profiles;

  # Declared profiles are copied in rather than symlinked: a link into
  # /nix/store would dangle inside the container. A manifest records which
  # files Nix owns, so a profile dropped from the config is removed while
  # hand-made profiles in the same directory are left alone.
  syncProfiles = pkgs.writeShellScript "wosarcher-sync-profiles" ''
    set -euo pipefail
    dir=${lib.escapeShellArg profilesDir}
    manifest="$dir/.nix-managed"
    if [ -f "$manifest" ]; then
      while IFS= read -r name; do
        [ -n "$name" ] && rm -f "$dir/$name"
      done < "$manifest"
    fi
    : > "$manifest"
    ${lib.concatStrings (
      lib.mapAttrsToList (name: file: ''
        install -m 0440 -o ${toString uid} -g ${toString gid} ${file} "$dir/${name}.toml"
        echo ${lib.escapeShellArg "${name}.toml"} >> "$manifest"
      '') profileFiles
    )}
  '';
in
{
  options._custom.services.ai.wosarcher = {
    enable = lib.mkEnableOption "the wosarcher research server";

    profile = lib.mkOption {
      type = lib.types.str;
      default = "embeddings-rerank";
      description = "Profile selected through WOSARCHER_PROFILE.";
    };

    llms = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            model = lib.mkOption {
              type = lib.types.str;
              description = "OmniRoute model or combo the profile's llm block calls.";
            };
            preset = lib.mkOption {
              type = models.type;
              description = ''
                Limits of the model behind the combo: a preset name
                (${models.names}) or { contextTokens; maxOutputTokens; }. For a
                combo that falls back between models, use its smallest member.
              '';
            };
            timeout = lib.mkOption {
              type = lib.types.number;
              default = 300;
              description = "Seconds wosarcher waits for one LLM response.";
            };
            research = lib.mkOption {
              type = toml.type;
              default = { };
              description = "Keys of the profile's research block, such as gap_context_tokens.";
            };
          };
        }
      );
      description = ''
        LLMs the generated profiles are built for. Every generated profile
        exists once per entry: the defaultLlm entry keeps the plain profile
        name, every other entry adds a "-<name>" suffix.
      '';
    };

    defaultLlm = lib.mkOption {
      type = lib.types.str;
      default = "deepseek";
      description = "Entry of llms used by the generated profiles without a suffix.";
    };

    profiles = lib.mkOption {
      type = lib.types.attrsOf toml.type;
      default = { };
      description = ''
        Profiles written to $XDG_CONFIG_HOME/wosarcher/profiles/<name>.toml.
        The generated profiles (embeddings-rerank, and with jev.enable
        embeddings-jev, bm25-jev and bm25-jev-wide, each once per entry of
        llms) are wired to this host's SearxNG,
        Firecrawl, Ollama, OmniRoute and, when enabled, the shared reranker;
        each of their keys can be overridden. Never put secrets here: they land in the Nix
        store. Pass them through environmentFile instead.
      '';
    };

    maxConcurrentRuns = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1;
      description = "Research runs the server executes at once.";
    };

    jev.enable = lib.mkEnableOption ''
      the TypeSafe Jev scorer: adds the embeddings-jev and bm25-jev profiles
      and passes personal-typesafe-api-key from secrets-sops/personal.yaml as
      WOSARCHER_SCORE__API_KEY
    '';

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Extra WOSARCHER_* variables, for secrets such as
        WOSARCHER_AUTH__PASSWORD_HASH or WOSARCHER_SCORE__API_KEY.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && wcfg.enable) {
    _custom.services.ai.wosarcher.llms = {
      # OmniRoute's research-smart combo: DeepSeek V4 Flash, 1M context.
      deepseek = {
        model = lib.mkDefault "research-smart";
        preset = lib.mkDefault "deepseek-v4-flash";
        timeout = lib.mkDefault 300;
        # The gap step reads the best passages so far; with a 1M window it can
        # read far more than wosarcher's 4000-token default. Switch to "auto"
        # once wosarcher's query-handling change lands.
        research.gap_context_tokens = lib.mkDefault 200000;
      };
      # OmniRoute's desktop-free combo (free Gemma 4 31B, then Ollama Cloud,
      # then the local gdesktop-qwen3.5:9b). The combo can fall back to the
      # local 32k model, so size for the smallest member.
      free = {
        model = lib.mkDefault "desktop-free";
        preset = lib.mkDefault "qwen3-5-9b-local";
        # Prompt processing of a large context on the local GPU is slow.
        timeout = lib.mkDefault 600;
        research.gap_context_tokens = lib.mkDefault 4000;
      };
    };

    _custom.services.ai.wosarcher.profiles = lib.mapAttrs (
      _: lib.mapAttrsRecursive (_: lib.mkDefault)
    ) generatedProfiles;

    _custom.services.web-proxies.wosarcher = {
      enable = true;
      subdomain = "wosarcher";
      inherit serviceName;
      publicPort = 20600;
      backendPort = 20601;
      lazy = true;
    };

    _custom.services.local-oci-images.wosarcher = {
      inherit source;
      tag = revision;
      imageName = "wosarcher";
    };

    virtualisation.oci-containers.containers.wosarcher = {
      inherit serviceName;
      cmd = [
        "wosarcher"
        "serve"
        "--host"
        wochap-ssc.meta.address
        "--port"
        (toString proxy.backendPort)
      ];
      volumes = [ "${dataDir}:/data:rw" ];
      environment = {
        WOSARCHER_PROFILE = wcfg.profile;
        WOSARCHER_SERVER__MAX_CONCURRENT_RUNS = toString wcfg.maxConcurrentRuns;
        # The browser's Origin is the nginx virtual host, not the backend
        # address, so state-changing requests need it allowed explicitly.
        WOSARCHER_AUTH__ALLOWED_ORIGINS = builtins.toJSON [
          "https://${proxy.subdomain}.${wochap-ssc.meta.domain}"
        ];
      };
      environmentFiles = [
        config.sops.templates."wosarcher.env".path
      ]
      ++ lib.optional (wcfg.environmentFile != null) wcfg.environmentFile;
      extraOptions = [
        "--network=host"
        "--cap-drop=all"
        "--security-opt=no-new-privileges"
        "--pids-limit=512"
      ];
    };

    sops.secrets.personal-typesafe-api-key = lib.mkIf wcfg.jev.enable {
      sopsFile = ../../../../../secrets-sops/personal.yaml;
      restartUnits = [ "${serviceName}.service" ];
    };

    sops.templates."wosarcher.env" = {
      mode = "0400";
      restartUnits = [ "${serviceName}.service" ];
      content = lib.generators.toKeyValue { } (
        {
          WOSARCHER_LLM__API_KEY = config.sops.placeholder.local-omniroute-secret-key;
        }
        # Every profile's score block gets this key; llama-server ignores it.
        // lib.optionalAttrs wcfg.jev.enable {
          WOSARCHER_SCORE__API_KEY = config.sops.placeholder.personal-typesafe-api-key;
        }
      );
    };

    systemd.tmpfiles.rules = [
      "d ${dataDir} 0750 ${toString uid} ${toString gid} -"
      "d ${dataDir}/config 0750 ${toString uid} ${toString gid} -"
      "d ${dataDir}/config/wosarcher 0750 ${toString uid} ${toString gid} -"
      "d ${profilesDir} 0750 ${toString uid} ${toString gid} -"
      "d ${dataDir}/share 0750 ${toString uid} ${toString gid} -"
      "d ${dataDir}/cache 0750 ${toString uid} ${toString gid} -"
    ];

    systemd.services.${serviceName} = {
      requires = [ "ollama.service" ];
      after = [ "ollama.service" ];
      preStart = lib.mkAfter ''
        ${syncProfiles}
      '';
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 2;
        TimeoutStopSec = lib.mkForce 45;
        UMask = "0027";
        ProtectHome = true;
      };
    };
  };
}
