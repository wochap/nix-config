{ config, lib, pkgs, inputs, ... }:

let
  cfg = config._custom.gui.discord;
  userName = config._userName;
in {
  options._custom.gui.discord = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    environment = { systemPackages = with pkgs; [ betterdiscordctl discord ]; };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "discord/settings.json".source = ./dotfiles/discord-settings.json;
        "BetterDiscord/themes/Dracula.theme.css".source =
          "${inputs.dracula-betterdiscord}/Dracula.theme.css";
      };
    };
  };
}
