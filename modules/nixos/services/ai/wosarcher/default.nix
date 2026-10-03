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
  defaultProfile = {
    run.gpu_policy = "shared";
    search = {
      provider = "searxng";
      base_url = "${host}:${toString searxProxy.publicPort}";
    };
    fetch = {
      provider = "firecrawl";
      base_url = "${host}:${toString firecrawlPublicPort}/v1";
    };
    prefilter = {
      provider = "embeddings";
      base_url = "http://127.0.0.1:11434/v1";
      model = cfg.ollamaEmbeddingModel;
      device = "local:gpu0";
    };
    score =
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
    llm = {
      provider = "llm";
      base_url = "${host}:${toString omniRouteProxy.publicPort}/v1";
      model = "research-smart";
      context_window = 131072;
    };
  };

  # TypeSafe Jev: a cloud scorer with calibrated 0-3 usefulness scores. It
  # sends every chunk to api.typesafe.ai, so it lives in its own profile and
  # the local reranker stays the default.
  jevScore = {
    provider = "jev";
    base_url = "https://api.typesafe.ai/v1";
    concurrency = 16;
    timeout = 120;
  };

  profileFiles = lib.mapAttrs (name: settings: toml.generate "wosarcher-${name}.toml" settings) wcfg.profiles;

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
      default = "nixos";
      description = "Profile selected through WOSARCHER_PROFILE.";
    };

    profiles = lib.mkOption {
      type = lib.types.attrsOf toml.type;
      default = { };
      description = ''
        Profiles written to $XDG_CONFIG_HOME/wosarcher/profiles/<name>.toml.
        The nixos profile is wired to this host's SearxNG, Firecrawl, Ollama,
        OmniRoute and, when enabled, the shared reranker; each of its
        keys can be overridden. Never put secrets here: they land in the Nix
        store. Pass them through environmentFile instead.
      '';
    };

    maxConcurrentRuns = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1;
      description = "Research runs the server executes at once.";
    };

    jev.enable = lib.mkEnableOption ''
      the TypeSafe Jev scorer: adds a nixos-jev profile, the nixos profile with
      score.provider = "jev", and passes personal-typesafe-api-key from
      secrets-sops/personal.yaml as WOSARCHER_SCORE__API_KEY
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
    _custom.services.ai.wosarcher.profiles = {
      nixos = lib.mapAttrsRecursive (_: lib.mkDefault) defaultProfile;
      nixos-jev = lib.mkIf wcfg.jev.enable (
        lib.mapAttrsRecursive (_: lib.mkDefault) (defaultProfile // { score = jevScore; })
      );
    };

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
