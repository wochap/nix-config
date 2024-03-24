{ config, lib, pkgs, inputs, ... }:

let cfg = config._custom.programs.discord;
in {
  options._custom.programs.discord.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [ betterdiscordctl discord ];

      xdg.configFile = {
        "discord/settings.json".source = ./dotfiles/discord-settings.json;
        "BetterDiscord/themes/mocha.theme.css".source =
          "${inputs.catppuccin-discord}/themes/mocha.theme.css";
      };
    };
  };
}
