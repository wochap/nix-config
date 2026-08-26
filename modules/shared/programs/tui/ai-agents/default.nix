{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.programs.ai-agents;
  inherit (config._custom.globals) userName configDirectory;
  hmConfig = config.home-manager.users.${userName};
  claude-session-duration = pkgs.writeScriptBin "claude-session-duration" (
    builtins.readFile ./scripts/claude-session-duration.sh
  );
  antigravity-nix-pkgs = inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  options._custom.programs.ai-agents = {
    enable = lib.mkEnableOption { };
    enableHandy = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      inputs.session-tap.packages."${stdenv.hostPlatform.system}".default
      _custom.rtk
      playwright-mcp
      playwright-driver
      claude-session-duration
      antigravity-nix-pkgs.default # Base App
      antigravity-nix-pkgs.google-antigravity-ide # IDE
      antigravity-nix-pkgs.google-antigravity-cli # CLI
    ];

    _custom.hm = {
      home = {
        packages =
          with pkgs;
          [ bubblewrap ]
          ++ lib.optionals cfg.enableHandy [ inputs.handy.packages.${stdenv.hostPlatform.system}.handy ];

        shellAliases = {
          cl = "sessiontap claude";
          cx = "sessiontap codex";
          qw = "sessiontap codex";
        };

        sessionVariables = {
          OPENSPEC_TELEMETRY = "0";
          CAVEMAN_DEFAULT_MODE = "ultra";
        };

        file = {
          ".claude/statusline.sh" = {
            source = ./scripts/claude-statusline.sh;
            executable = true;
          };
          ".claude/hooks/claude-notify.sh" = {
            source = ./scripts/claude-notify.sh;
            executable = true;
          };
          ".gemini/antigravity-cli/hooks/agy-notify.sh" = {
            source = ./scripts/agy-notify.sh;
            executable = true;
          };
          ".gemini/antigravity-cli/hooks.json".source =
            lib._custom.relativeSymlink configDirectory ./dotfiles/agy/hooks.json;
          ".gemini/config/hooks.json".source =
            lib._custom.relativeSymlink configDirectory ./dotfiles/agy/hooks.json;
          ".qwen/hooks/qwen-notify.sh" = {
            source = ./scripts/qwen-notify.sh;
            executable = true;
          };

          ".pi/agent/models.json".source =
            lib._custom.relativeSymlink configDirectory ./dotfiles/pi/models.json;

          ".codex/model-catalog.local.json".source =
            lib._custom.relativeSymlink configDirectory ./dotfiles/codex/model-catalog.local.json;
          ".codex/hooks/codex-notify.sh" = {
            source = ./scripts/codex-notify.sh;
            executable = true;
          };
        };

        symlinks = {
          "${hmConfig.home.homeDirectory}/.gemini/antigravity-cli/skills" =
            "${hmConfig.home.homeDirectory}/.agents/skills";
        };

        copyFiles = {
          ".claude/settings.json".source = ./dotfiles/claude-settings.json;
          ".qwen/settings.json".source = ./dotfiles/qwen-settings.json;
          ".pi/agent/settings.json".source = ./dotfiles/pi/settings.json;
          ".codex/config.toml".source = ./dotfiles/codex/config.toml;
          ".codex/hooks.json".source = ./dotfiles/codex/hooks.json;
          ".config/opencode/opencode.jsonc".source = ./dotfiles/opencode-settings.jsonc;
          ".gemini/antigravity-cli/settings.json".source = ./dotfiles/agy/settings.json;
        };
      };

      xdg.configFile."opencode/plugins/opencode-notify.ts".source = ./scripts/opencode-notify.ts;
    };
  };
}
