{ config, lib, pkgs, inputs, ... }:

let userName = config._userName;
in {
  config = {
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
