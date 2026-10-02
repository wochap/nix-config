{
  config,
  lib,
  ...
}:

let
  cfg = config._custom.programs.ai-agents;
  inherit (config._custom.globals) configDirectory;
  skill = lib._custom.relativeSymlink configDirectory ./skill;
in
{
  options._custom.programs.ai-agents.cartridge = {
    enable = lib.mkEnableOption { };
  };

  config = lib.mkIf (cfg.enable && cfg.cartridge.enable) {
    _custom.hm.home.file = {
      # pi, codex and antigravity read ~/.agents/skills
      ".agents/skills/cartridge".source = skill;
      ".claude/skills/cartridge".source = skill;
    };
  };
}
