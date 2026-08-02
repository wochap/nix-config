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
          [ ] ++ lib.optionals cfg.enableHandy [ inputs.handy.packages.${stdenv.hostPlatform.system}.handy ];

        sessionVariables = {
          OPENSPEC_TELEMETRY = "0";
          CAVEMAN_DEFAULT_MODE = "ultra";
        };

        file = {
          ".claude/hooks/claude-notify.sh" = {
            source = ./scripts/claude-notify.sh;
            executable = true;
          };
          ".gemini/antigravity-cli/hooks/agy-notify.sh" = {
            source = ./scripts/agy-notify.sh;
            executable = true;
          };
          ".gemini/antigravity-cli/hooks.json".source =
            lib._custom.relativeSymlink configDirectory ./dotfiles/agy-hooks.json;
          ".gemini/config/hooks.json".source =
            lib._custom.relativeSymlink configDirectory ./dotfiles/agy-hooks.json;
          ".qwen/hooks/qwen-notify.sh" = {
            source = ./scripts/qwen-notify.sh;
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
        };
      };
    };
  };
}
