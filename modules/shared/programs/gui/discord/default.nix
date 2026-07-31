{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config._custom.programs.discord;
in
{
  options._custom.programs.discord = {
    enable = lib.mkEnableOption { };

    pkg = lib.mkOption {
      type = lib.types.package;
      default = pkgs.discord;
      description = "Discord package to install and confine. For variants like discord-canary, also override _custom.security.apparmor.policies.discord.dir and binary.";
    };
  };

  config = lib.mkIf cfg.enable {
    _custom.security.apparmor.policies.discord = {
      enable = lib.mkDefault true;
      pkg = lib.mkDefault cfg.pkg;
    };

    _custom.hm = {
      home.packages = with pkgs; [
        betterdiscordctl
        cfg.pkg
        legcord # discord client
        equicord # discord client mod
      ];

      xdg.configFile = {
        "discord/settings.json".source = ./dotfiles/discord-settings.json;
        "BetterDiscord/themes/latte.theme.css".source =
          "${inputs.catppuccin-discord}/themes/latte.theme.css";
        "BetterDiscord/themes/frappe.theme.css".source =
          "${inputs.catppuccin-discord}/themes/frappe.theme.css";
        "BetterDiscord/themes/macchiato.theme.css".source =
          "${inputs.catppuccin-discord}/themes/macchiato.theme.css";
        "BetterDiscord/themes/mocha.theme.css".source =
          "${inputs.catppuccin-discord}/themes/mocha.theme.css";
      };
    };
  };
}
