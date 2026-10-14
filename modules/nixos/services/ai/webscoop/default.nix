{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.services.ai;
  inherit (pkgs._custom) wochap-ssc;
  webscoop = inputs.webscoop.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # Node ignores the system store, so trust the local CA used by omniroute.wochap.local
  environment.NODE_EXTRA_CA_CERTS = "${wochap-ssc}/rootCA.pem";

  # Hyprland: keep the browser on a special workspace (webscoop adds the
  # window rule at run time) and bring it to the current one only when needed.
  webscoopWindow = pkgs.writeScriptBin "webscoop-window" (
    builtins.readFile ./scripts/webscoop-window.sh
  );
  windowCmd = action: "${lib.getExe webscoopWindow} ${action}";

  healthcheck = pkgs.writeShellApplication {
    name = "webscoop-healthcheck";
    runtimeInputs = [
      webscoop
      pkgs.jq
      pkgs.libnotify
    ];
    runtimeEnv.NODE_EXTRA_CA_CERTS = environment.NODE_EXTRA_CA_CERTS;
    text = builtins.readFile ./scripts/webscoop-healthcheck.sh;
  };
  healthcheckArgs = lib.escapeShellArgs (
    [
      (toString cfg.webscoop.healthcheck.tolerance)
      cfg.webscoop.healthcheck.query
    ]
    ++ lib.mapAttrsToList (recipe: count: "${recipe}=${toString count}") cfg.webscoop.healthcheck.expected
  );

  # GET /webscoop/<recipe>?a=1&b=2 -> webscoop run <recipe> --var a=1 --var b=2
  # Replies with the JSON array of rows.
  webscoopRun = pkgs.writeShellScript "webscoop-run" ''
    recipe=$1
    # entire-query is a JSON object, turn each pair into "--var" "k=v".
    # In "query", spaces become "+" so recipes build clean search URLs (q=a+b),
    # otherwise the engines redirect to a URL with extra tracking params.
    mapfile -d "" vars < <(${lib.getExe pkgs.jq} -j 'to_entries[] | .key as $k | (.value | tostring | if $k == "query" then gsub(" "; "+") else . end) as $v | "--var\u0000\($k)=\($v)\u0000"' <<<"$2")
    export NODE_EXTRA_CA_CERTS=${environment.NODE_EXTRA_CA_CERTS}
    err=$(mktemp)
    trap 'rm -f "$err"' EXIT
    # webhook returns stdout+stderr together, keep stderr out of the JSON
    ${lib.getExe webscoop} run "$recipe" --quiet \
      --queue-timeout 40000 --guard-timeout 20000 \
      "''${vars[@]}" 2>"$err" || { cat "$err" >&2; exit 1; }
  '';

  mkHook = recipe: {
    id = "webscoop/${recipe}";
    execute-command = "${webscoopRun}";
    http-methods = [ "GET" ];
    include-command-output-in-response = true;
    response-headers = [
      {
        name = "Content-Type";
        value = "application/json";
      }
    ];
    pass-arguments-to-command = [
      {
        source = "string";
        name = recipe;
      }
      { source = "entire-query"; }
    ];
  };
in
{
  options._custom.services.ai.webscoop = {
    enable = lib.mkEnableOption { };
    healthcheck = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run a daily canary that notifies when a search recipe returns a different number of results.";
      };
      onCalendar = lib.mkOption {
        type = lib.types.str;
        default = "*-*-* 09:00:00";
        description = "systemd OnCalendar for the healthcheck.";
      };
      query = lib.mkOption {
        type = lib.types.str;
        default = "cats";
        description = "Search query used by the healthcheck.";
      };
      tolerance = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 1;
        description = "Allowed difference (+/-) between the expected and actual result count.";
      };
      expected = lib.mkOption {
        type = lib.types.attrsOf lib.types.ints.positive;
        # Snapshot taken 2026-10-14 with query "cats".
        default = {
          google-search-results = 8;
          duckduckgo-search-results = 10;
          bing-search-results = 8;
        };
        description = "Expected number of results per recipe; update when a search engine legitimately changes.";
      };
    };
    webhook = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Expose webscoop recipes through the webhook service.";
      };
      recipes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "google-search-results"
          "duckduckgo-search-results"
          "bing-search-results"
        ];
        description = "Recipes served at https://webhook.<domain>/webscoop/<recipe>?<var>=<value>&...";
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.webscoop.enable) {
    _custom.hm = {
      imports = [ inputs.webscoop.homeManagerModules.webscoop ];

      home.packages = [ healthcheck ];

      systemd.user.services.webscoop-healthcheck = lib.mkIf cfg.webscoop.healthcheck.enable {
        Unit.Description = "Check webscoop search recipes still return the expected result count";
        Service = {
          Type = "oneshot";
          # Timers catch up right after resume, before the network is back.
          ExecStartPre = lib.optional config.networking.networkmanager.enable "${config.networking.networkmanager.package}/bin/nm-online -s -q -t 120";
          ExecStart = "${lib.getExe healthcheck} ${healthcheckArgs}";
          TimeoutStartSec = "15min";
        };
      };
      systemd.user.timers.webscoop-healthcheck = lib.mkIf cfg.webscoop.healthcheck.enable {
        Unit.Description = "Schedule the webscoop recipes healthcheck";
        Timer = {
          OnCalendar = cfg.webscoop.healthcheck.onCalendar;
          Persistent = true;
          Unit = "webscoop-healthcheck.service";
        };
        Install.WantedBy = [ "timers.target" ];
      };

      programs.webscoop = {
        enable = true;
        package = webscoop;
        inherit environment;
        settings = {
          browser = {
            driver = "patchright";
            channel = "chrome";
            timezone = "America/Panama";
            locale = "en-US";
            args = [ "--class=webscoop" ];
          };
          profiles.default = "default";
          # Different search recipes run in parallel tabs, one run per recipe at a time.
          daemon.concurrency = {
            total = lib.mkDefault 10;
            perRecipe = lib.mkDefault 2;
          };
          hooks = {
            "browser.show" = windowCmd "show";
            "browser.hide" = windowCmd "hide";
            "browser.started" = ''case "$WEBSCOOP_COMMAND" in run|test) ${windowCmd "hide"} ;; esac'';
            "run.failed" = windowCmd "show";
            "attention.needed" = windowCmd "show";
            "attention.resolved" = windowCmd "hide";
          };
          llm = lib.mkIf cfg.enableOmniRoute {
            endpoint = "https://omniroute.wochap.local/v1";
            model = "desktop-free";
            apiKeyFile = config.sops.secrets.local-omniroute-secret-key.path;
            contextTokens = 32768;
            timeoutMs = 30000;
          };
        };
      };
    };

    _custom.services.webhook = lib.mkIf cfg.webscoop.webhook.enable {
      enable = lib.mkDefault true;
      hooks = map mkHook cfg.webscoop.webhook.recipes;
    };
  };
}
