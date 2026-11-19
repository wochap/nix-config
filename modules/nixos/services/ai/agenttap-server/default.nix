{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  inherit (pkgs._custom) wochap-ssc;
  inherit (config._custom.globals) userName;
  proxy = config._custom.services.web-gate.proxies.agenttap-server;
  apiKeyFile = config.sops.secrets.agenttap-server-api-key.path;
in
{
  options._custom.services.ai.agenttapServer = {
    enable = lib.mkEnableOption "OpenAI-compatible API over the agenttap CLI";
    cwd = lib.mkOption {
      type = lib.types.str;
      default = "/home/${userName}/agenttap";
      description = "Working directory of every agent run; created on service start.";
    };
    models = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "claude/claude-opus-5-5[1m]"
        "claude/claude-sonnet-5-5"
        "claude/claude-haiku-5-5"
        "agy/gemini-4-argon"
        "agy/gemini-4-neon"
        "agy/gemini-4-hydrogen"
      ];
      description = "<agent>/<model> ids listed by /v1/models.";
    };
    tools = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Let runs use tools (agenttap serve --tools). Off, every run gets
        --no-tools, so a prompt cannot drive tools in cwd; wosarcher, which
        forwards scraped web text, requires it off.
      '';
    };
    toolEvents = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Stream tool calls as italic lines (only with tools on).";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.agenttapServer.enable) {
    # Clients send it as "Authorization: Bearer <key>".
    sops.secrets.agenttap-server-api-key = {
      sopsFile = ../../../../../secrets-sops/local.yaml;
      key = "local-agenttap-server-api-key";
      owner = userName;
      mode = "0400";
    };

    # https://agenttap.wochap.local/v1
    _custom.services.web-gate.proxies.agenttap-server = {
      enable = true;
      subdomain = "agenttap";
      publicPort = 20940;
      backendPort = 20941;
      lazy = true;
      serviceScope = "user";
      inherit userName;
    };

    _custom.hm.systemd.user.services.agenttap-server = {
      # Not tied to the graphical session: the lazy socket starts it in the
      # lingering user manager, and the socket proxy would keep sending
      # requests to a dead port after a logout stopped it.
      Unit.Description = "OpenAI-compatible API over the agenttap CLI";
      Service = {
        ExecStartPre = lib.escapeShellArgs [
          "${pkgs.coreutils}/bin/mkdir"
          "-p"
          cfg.agenttapServer.cwd
        ];
        ExecStart = lib.escapeShellArgs (
          [
            (lib.getExe pkgs._custom.agenttap)
            "serve"
            "--host"
            wochap-ssc.meta.address
            "--port"
            (toString proxy.backendPort)
            "-C"
            cfg.agenttapServer.cwd
            "--models"
            (lib.concatStringsSep "," cfg.agenttapServer.models)
            "--api-key-file"
            apiKeyFile
          ]
          ++ lib.optionals cfg.agenttapServer.tools (
            [ "--tools" ] ++ lib.optional cfg.agenttapServer.toolEvents "--tool-events"
          )
        );
        Restart = "always";
        RestartSec = 2;
        # SIGTERM exits 130 (term.ts), a normal stop.
        SuccessExitStatus = 130;
        # sessiontap comes from the system profile; claude (npm), pi (bun)
        # and agy are in PATH, see programs/dev/lang-web.
        Environment = [
          "PATH=%h/.npm-packages/bin:%h/.cache/.bun/bin:/etc/profiles/per-user/${userName}/bin:/run/current-system/sw/bin"
        ];
      }
      // lib._custom.userServiceHardening
      // {
        # The harnesses write ~/.claude, ~/.config/pi, ~/.gemini, ~/.local/state/agenttap
        # and the run's cwd, so home stays visible and writable.
        ReadWritePaths = [ "%h" ];
        BindReadOnlyPaths = [ apiKeyFile ];
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        # Bubblewrap requires user and mount namespaces for agent sandboxing
        RestrictNamespaces = false;
      };
    };
  };
}
