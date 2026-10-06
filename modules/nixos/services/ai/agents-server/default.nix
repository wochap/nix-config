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
  proxy = config._custom.services.web-proxies.agents-server;
in
{
  options._custom.services.ai.agentsServer = {
    enable = lib.mkEnableOption "OpenAI-compatible API over the agents CLI";
    cwd = lib.mkOption {
      type = lib.types.str;
      default = "/home/${userName}";
      description = "Working directory of every agent run.";
    };
    models = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "claude/claude-opus-5-5[1m]"
        "pi/omniroute/desktop-free"
      ];
      description = "<agent>/<model> ids listed by /v1/models.";
    };
    noTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Runs get no tools (agents run --no-tools): the agents only answer.";
    };
    toolEvents = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Stream tool calls as italic lines (only with noTools off).";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.agentsServer.enable) {
    # https://agents.wochap.local/v1
    _custom.services.web-proxies.agents-server = {
      enable = true;
      subdomain = "agents";
      publicPort = 20940;
      backendPort = 20941;
      lazy = true;
      serviceScope = "user";
      inherit userName;
    };

    _custom.hm.systemd.user.services.agents-server = {
      Unit = {
        Description = "OpenAI-compatible API over the agents CLI";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = lib.escapeShellArgs (
          [
            (lib.getExe pkgs._custom.agents)
            "serve"
            "--host"
            wochap-ssc.meta.address
            "--port"
            (toString proxy.backendPort)
            "-C"
            cfg.agentsServer.cwd
            "--models"
            (lib.concatStringsSep "," cfg.agentsServer.models)
          ]
          ++ lib.optional cfg.agentsServer.noTools "--no-tools"
          ++ lib.optional cfg.agentsServer.toolEvents "--tool-events"
        );
        Restart = "on-failure";
        RestartSec = 2;
        # SIGTERM exits 130 (term.ts), a normal stop.
        SuccessExitStatus = 130;
        # sessiontap comes from the system profile; claude (npm) and pi (bun)
        # are global installs in home, see programs/dev/lang-web.
        Environment = [
          "PATH=%h/.npm-packages/bin:%h/.cache/.bun/bin:/etc/profiles/per-user/${userName}/bin:/run/current-system/sw/bin"
        ];
      }
      // lib._custom.userServiceHardening
      // {
        # The harnesses write ~/.claude, ~/.config/pi, ~/.local/state/agents
        # and the run's cwd, so home stays visible and writable.
        ReadWritePaths = [ "%h" ];
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
      };
    };
  };
}
