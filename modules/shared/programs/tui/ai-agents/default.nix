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
  new-project = pkgs.writeScriptBin "new-project" (builtins.readFile ./scripts/new-project.sh);
  skills = {
    agents = ../../../../../packages/agents/skill;
    openspec-pipeline = ../../../../../packages/openspec-pipeline/skill;
  };
  mkSkillLinks =
    dir:
    lib.mapAttrs' (
      name: path:
      lib.nameValuePair "${dir}/${name}" { source = lib._custom.relativeSymlink configDirectory path; }
    ) skills;
in
{
  imports = [ ./sessiontap.nix ];

  options._custom.programs.ai-agents = {
    enable = lib.mkEnableOption { };
    enableSkills = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      _custom.rtk
      playwright-mcp
      playwright-driver
      inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli # CLI
      new-project
      _custom.openspec-pipeline
      _custom.agents
    ];

    _custom.hm = {
      home = {
        packages = with pkgs; [ bubblewrap ];

        sessionVariables = {
          OPENSPEC_TELEMETRY = "0";
          CAVEMAN_DEFAULT_MODE = "ultra";
        };

        file =
          lib.optionalAttrs cfg.enableSkills (
            mkSkillLinks ".claude/skills" // mkSkillLinks ".pi/agent/skills"
          )
          // {
            ".claude/statusline.sh" = {
              source = ./scripts/claude-statusline.sh;
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

            ".codex/model-catalog.local.json".source =
              lib._custom.relativeSymlink configDirectory ./dotfiles/codex/model-catalog.local.json;
          };

        symlinks = {
          "${hmConfig.home.homeDirectory}/.gemini/antigravity-cli/skills" =
            "${hmConfig.home.homeDirectory}/.agents/skills";
        };

        copyFiles = {
          ".claude/settings.json".source = ./dotfiles/claude-settings.json;
          ".qwen/settings.json".source = ./dotfiles/qwen-settings.json;
          ".pi/agent/settings.json".source = ./dotfiles/pi/settings.json;
          ".pi/agent/models.json".source = ./dotfiles/pi/models.json;
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
