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
  webscoopUnwrapped = inputs.webscoop.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # Node ignores the system store, so trust the local CA used by omniroute.wochap.local
  webscoop = pkgs.symlinkJoin {
    name = "webscoop-wrapped";
    paths = [ webscoopUnwrapped ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/webscoop \
        --set NODE_EXTRA_CA_CERTS ${wochap-ssc}/rootCA.pem
    '';
    meta.mainProgram = "webscoop";
  };

  # GET /webscoop/<recipe>?a=1&b=2 -> webscoop run <recipe> --var a=1 --var b=2
  # Replies with the JSON array of rows.
  webscoopRun = pkgs.writeShellScript "webscoop-run" ''
    recipe=$1
    # entire-query is a JSON object, turn each pair into "--var" "k=v"
    mapfile -d "" vars < <(${lib.getExe pkgs.jq} -j 'to_entries[] | "--var\u0000\(.key)=\(.value | tostring)\u0000"' <<<"$2")
    err=$(mktemp)
    trap 'rm -f "$err"' EXIT
    # webhook returns stdout+stderr together, keep stderr out of the JSON
    ${lib.getExe webscoop} run "$recipe" --quiet \
      --lock-timeout 40000 --guard-timeout 20000 \
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
    environment.systemPackages = [ webscoop ];

    _custom.hm.xdg.configFile."webscoop/config.json".text = builtins.toJSON {
      browser = {
        driver = "patchright";
        channel = "chrome";
        timezone = "America/Panama";
        locale = "en-US";
      };
      profiles.default = "default";
      llm = lib.mkIf cfg.enableOmniRoute {
        endpoint = "https://omniroute.wochap.local/v1";
        model = "desktop-free";
        apiKeyFile = config.sops.secrets.local-omniroute-secret-key.path;
        contextTokens = 32768;
        timeoutMs = 30000;
      };
    };

    _custom.services.webhook = lib.mkIf cfg.webscoop.webhook.enable {
      enable = lib.mkDefault true;
      hooks = map mkHook cfg.webscoop.webhook.recipes;
    };
  };
}
