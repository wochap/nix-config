{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  rcfg = cfg.reranker;
  inherit (pkgs._custom) wochap-ssc;

  # A Qwen3-Reranker GGUF served by llama-server behind /v1/rerank. llama.cpp
  # allocates only weights plus KV cache, so the reranker and the Ollama
  # embedding model stay resident on the same GPU and need no phase
  # scheduling. Shared by GPT Researcher and wosarcher.
  serviceName = "reranker";
  modelServiceName = "${serviceName}-model";
  proxy = config._custom.services.web-proxies.reranker;
  isRocm = rcfg.accelerator == "rocm";
  modelDir = "/var/lib/reranker";
  modelPath = "${modelDir}/${rcfg.modelFile}";
  # --pooling rank selects the classifier head the reranker GGUF carries; the
  # server applies the model's own tokenizer.chat_template.rerank per pair.
  serverCmd = [
    (lib.getExe' rcfg.package "llama-server")
    "--model"
    modelPath
    "--rerank"
    "--pooling"
    "rank"
    "--ctx-size"
    (toString rcfg.contextSize)
    # Pooling needs each query+document pair inside one physical batch, and
    # llama-server clamps --batch-size to --ubatch-size (512 by default), which
    # rejects any pair longer than 512 tokens.
    "--batch-size"
    (toString rcfg.contextSize)
    "--ubatch-size"
    (toString rcfg.contextSize)
    "--n-gpu-layers"
    (toString rcfg.gpuLayers)
    "--host"
    wochap-ssc.meta.address
    "--port"
    (toString proxy.backendPort)
  ]
  # /metrics carries the token counters the idle watchdog samples.
  ++ lib.optional (rcfg.idleTimeout != null) "--metrics"
  ++ rcfg.extraArgs;

  # The GGUF lives outside the store: it is several GB, and pinning it there
  # would re-download it on every URL change. Verified against modelSha256
  # when one is set; the recorded hash doubles as the skip marker.
  fetchModel = pkgs.writeShellScript "fetch-reranker-model" ''
    set -euo pipefail
    curl=${lib.getExe pkgs.curl}
    sha256sum=${lib.getExe' pkgs.coreutils "sha256sum"}
    model=${lib.escapeShellArg modelPath}
    url=${lib.escapeShellArg rcfg.modelUrl}
    want=${lib.escapeShellArg (if rcfg.modelSha256 == null then "" else rcfg.modelSha256)}
    stamp="$model.sha256"

    if [ -f "$model" ]; then
      if [ -z "$want" ] || [ "$(cat "$stamp" 2>/dev/null || true)" = "$want" ]; then
        exit 0
      fi
      echo "Reranker model present but does not match modelSha256; re-downloading" >&2
    fi

    "$curl" --location --fail --retry 5 --retry-delay 5 --retry-connrefused \
      --retry-all-errors --continue-at - --output "$model.part" "$url"

    got="$("$sha256sum" "$model.part" | cut -d' ' -f1)"
    if [ -n "$want" ] && [ "$got" != "$want" ]; then
      echo "Reranker model sha256 mismatch: expected $want, got $got" >&2
      rm -f "$model.part"
      exit 1
    fi

    mv "$model.part" "$model"
    printf '%s' "$got" > "$stamp"
    echo "Reranker model ready: $model (sha256 $got)"
  '';

  # llama.cpp never unloads on its own, so the server would hold its VRAM
  # until something stops it. Sample the served-token counter: while it stands
  # still no rerank has been served, and after idleTimeout the unit stops. The
  # lazy socket proxy starts it again on the next request, at a few seconds'
  # cost.
  idleWatchdog = pkgs.writeShellScript "reranker-idle" ''
    set -euo pipefail
    curl=${lib.getExe pkgs.curl}
    jq=${lib.getExe pkgs.jq}
    systemctl=${lib.getExe' pkgs.systemd "systemctl"}
    unit=${lib.escapeShellArg "${serviceName}.service"}
    base=http://${wochap-ssc.meta.address}:${toString proxy.backendPort}
    idle=${toString (rcfg.idleTimeout * 60)}
    state=/run/reranker-idle

    "$systemctl" is-active --quiet "$unit" || exit 0

    # Rises once per decode batch. llamacpp:prompt_tokens_total stays at 0 for
    # pooling requests, so it cannot serve as the activity signal here.
    served="$("$curl" -sf --max-time 5 "$base/metrics" \
      | ${lib.getExe pkgs.gawk} '/^llamacpp:n_decode_total /{print $2}')" || exit 0
    [ -n "$served" ] || exit 0

    now="$(date +%s)"
    last_served=""
    last_change="$now"
    if [ -f "$state" ]; then
      read -r last_served last_change < "$state" || true
    fi

    if [ "$served" != "$last_served" ]; then
      echo "$served $now" > "$state"
      exit 0
    fi

    # A rejected request never reaches decode, so the counter above misses it.
    # The server still logs it, and a client retrying against errors is not idle.
    if ${lib.getExe' pkgs.systemd "journalctl"} -q -o cat -u "$unit" --since "@$last_change" \
      | ${lib.getExe pkgs.gnugrep} 'send_error' > /dev/null; then
      echo "$served $now" > "$state"
      exit 0
    fi

    # Never stop mid-request: a batch in flight leaves a slot processing.
    if "$curl" -sf --max-time 5 "$base/slots" | "$jq" -e 'any(.[]; .is_processing)' > /dev/null; then
      echo "$served $now" > "$state"
      exit 0
    fi

    if [ "$((now - last_change))" -ge "$idle" ]; then
      echo "No rerank served in ${toString rcfg.idleTimeout} min; stopping $unit to release its VRAM"
      rm -f "$state"
      "$systemctl" stop "$unit"
    fi
  '';

  # llama-server binds its port before loading the model and answers 503 until
  # the load finishes. The lazy proxy only waits for the port and starts after
  # this unit, so holding the unit in "activating" until /health returns 200
  # keeps the first rerank of a run from hitting the 503.
  waitHealthy = pkgs.writeShellScript "reranker-wait-healthy" ''
    for attempt in {1..240}; do
      ${lib.getExe pkgs.curl} -sf --max-time 2 \
        http://${wochap-ssc.meta.address}:${toString proxy.backendPort}/health > /dev/null && exit 0
      ${lib.getExe' pkgs.coreutils "sleep"} 0.5
    done
    echo "llama-server did not report healthy within 120 s" >&2
    exit 1
  '';
in
{
  options._custom.services.ai.reranker = {
    enable = lib.mkEnableOption "the shared llama-server reranker";

    accelerator = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "cuda"
          "rocm"
        ]
      );
      default =
        if cfg.enableCuda then
          "cuda"
        else if cfg.enableRocm then
          "rocm"
        else
          null;
      defaultText = lib.literalExpression ''"cuda" when enableCuda, "rocm" when enableRocm'';
      description = "GPU backend; selects the default llama.cpp package.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = if isRocm then pkgs.llama-cpp-rocm else pkgs.llama-cpp.override { cudaSupport = true; };
      defaultText = lib.literalExpression "pkgs.llama-cpp-rocm on ROCm, pkgs.llama-cpp.override { cudaSupport = true; } on CUDA";
      example = lib.literalExpression "pkgs.llama-cpp-vulkan";
      description = ''
        llama.cpp build serving the reranker. llama-cpp-rocm comes from
        cache.nixos.org and already covers every gfx target ROCm itself was
        built for, gfx1030 included. The CUDA build is not cached and
        compiles locally; pkgs.llama-cpp-vulkan is the cached alternative on
        NVIDIA, at some throughput cost.
      '';
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "Qwen/Qwen3-Reranker-4B";
      description = ''
        Model name clients send in each rerank request. llama-server ignores
        it in single-model mode; the served weights come from modelUrl.
      '';
    };

    modelUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://huggingface.co/giladgd/Qwen3-Reranker-4B-GGUF/resolve/main/Qwen3-Reranker-4B.Q8_0.gguf";
      description = ''
        GGUF downloaded once into ${modelDir}. It must come from a
        conversion through llama.cpp's reranker path: such files carry the
        cls.output.weight tensor and a tokenizer.chat_template.rerank key.
        A plain causal-LM Qwen3-Reranker conversion has no classifier head
        and cannot rerank.
      '';
    };

    modelSha256 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "0b1c…";
      description = ''
        Expected sha256 of the GGUF. null downloads without verification and
        logs the hash it got, which is what you pin here afterwards.
      '';
    };

    modelFile = lib.mkOption {
      type = lib.types.str;
      default = baseNameOf rcfg.modelUrl;
      defaultText = lib.literalExpression "baseNameOf modelUrl";
      description = "File name the GGUF is stored under inside ${modelDir}.";
    };

    endpoint = lib.mkOption {
      type = lib.types.str;
      default = "/v1/rerank";
      description = ''
        Rerank path on llama-server. Builds have exposed /rerank,
        /v1/rerank and /v1/reranking; all take the same request shape.
      '';
    };

    contextSize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4096;
      description = ''
        llama-server --ctx-size. Must cover the rerank template plus the
        query plus the longest document a client sends.
      '';
    };

    idleTimeout = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = 15;
      example = lib.literalExpression "null";
      description = ''
        Minutes without a served rerank after which the server is stopped
        and its VRAM released; the lazy proxy restarts it on the next
        request. null keeps it resident once started.
      '';
    };

    gpuLayers = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 99;
      description = "llama-server --n-gpu-layers; 99 offloads the whole model.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "--parallel"
        "4"
      ];
      description = "Extra arguments appended to llama-server.";
    };

    rocm.gfxOverride = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "10.3.0";
      description = ''
        HSA_OVERRIDE_GFX_VERSION, for a card that needs to present itself as
        another architecture. Unnecessary for any target llama-cpp-rocm
        already covers.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && rcfg.enable) {
    assertions = [
      {
        assertion = rcfg.accelerator != null;
        message = ''
          _custom.services.ai.reranker.enable needs a GPU backend: set
          enableCuda, enableRocm, or _custom.services.ai.reranker.accelerator.
        '';
      }
      {
        assertion = lib.hasSuffix ".gguf" rcfg.modelFile;
        message = "_custom.services.ai.reranker.modelFile must name a .gguf; llama-server serves GGUF weights only";
      }
    ];

    _custom.services.web-proxies.reranker = {
      enable = true;
      subdomain = "reranker";
      inherit serviceName;
      publicPort = 20820;
      backendPort = 20821;
      lazy = true;
    };

    # llama-server runs as root.
    systemd.tmpfiles.rules = [
      "d ${modelDir} 0750 root root -"
      "Z ${modelDir} - root root -"
    ];

    systemd.timers."${serviceName}-idle" = lib.mkIf (rcfg.idleTimeout != null) {
      description = "Check whether the reranker has gone idle";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "1min";
        AccuracySec = "30s";
      };
    };

    systemd.services = {
      # Downloading several GB cannot happen inside the lazy proxy's start
      # window, so the GGUF is fetched by its own unit. It is deliberately not
      # wanted by multi-user.target: switch-to-configuration would otherwise
      # start it and block the whole switch for the length of the download.
      # The server unit pulls it in on first use instead.
      ${modelServiceName} = {
        description = "Download the reranker GGUF";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeoutStartSec = "2h";
          ExecStart = fetchModel;
          UMask = "0027";
          ProtectHome = true;
        };
      };

      "${serviceName}-idle" = lib.mkIf (rcfg.idleTimeout != null) {
        description = "Stop the reranker once it has gone idle";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = idleWatchdog;
        };
      };

      ${serviceName} = {
        description = "Qwen3-Reranker served by llama-server";
        requires = [ "${modelServiceName}.service" ];
        after = [ "${modelServiceName}.service" ];
        # A server that cannot start must not be restarted forever: it would
        # hold VRAM in a loop while the embedding model needs it.
        startLimitIntervalSec = 300;
        startLimitBurst = 3;
        environment = lib.optionalAttrs (isRocm && rcfg.rocm.gfxOverride != null) {
          HSA_OVERRIDE_GFX_VERSION = rcfg.rocm.gfxOverride;
        };
        serviceConfig = {
          ExecStart = lib.escapeShellArgs serverCmd;
          ExecStartPost = waitHealthy;
          TimeoutStartSec = 150;
          Restart = "on-failure";
          RestartSec = 5;
          TimeoutStopSec = 60;
          UMask = "0027";
          ProtectHome = true;
          # The GGUF is the only state it touches, and only for reading.
          ProtectSystem = "strict";
          ReadOnlyPaths = [ modelDir ];
          NoNewPrivileges = true;
          PrivateTmp = true;
        };
      };
    };
  };
}
