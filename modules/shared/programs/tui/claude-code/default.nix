{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.programs.claude-code;
  inherit (config._custom.globals) configDirectory;
  claude-session-duration = pkgs.writeScriptBin "claude-session-duration" (
    builtins.readFile ./scripts/claude-session-duration.sh
  );
in
{
  options._custom.programs.claude-code.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ claude-session-duration ];

    _custom.hm = {
      home = {
        sessionVariables.CAVEMAN_LEVEL = "ultra";
        file = {
          ".claude/hooks/claude-notify.sh".source =
            lib._custom.relativeSymlink configDirectory ./scripts/claude-notify.sh;
          ".claude/settings.json".source =
            lib._custom.relativeSymlink configDirectory ./dotfiles/claude-settings.json;
        };
      };
    };
  };
}
