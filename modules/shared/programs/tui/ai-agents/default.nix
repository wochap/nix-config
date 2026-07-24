{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.programs.ai-agents;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  claude-session-duration = pkgs.writeScriptBin "claude-session-duration" (
    builtins.readFile ./scripts/claude-session-duration.sh
  );
in
{
  options._custom.programs.ai-agents.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      claude-session-duration
      inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.default # Base App
      inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-ide # IDE
      inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli # CLI
    ];

    _custom.hm = {
      home = {
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
