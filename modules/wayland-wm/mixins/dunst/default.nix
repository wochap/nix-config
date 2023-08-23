{ config, pkgs, lib, ... }:

let
  cfg = config._custom.waylandWm;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/wayland-wm/mixins/dunst";
  dunst-toggle-mode = pkgs.writeTextFile {
    name = "dunst-toggle-mode";
    destination = "/bin/dunst-toggle-mode";
    executable = true;
    text = builtins.readFile ./scripts/dunst-toggle-mode.sh;
  };
  dunst-play-notification-sound = pkgs.writeTextFile {
    name = "dunst-play-notification-sound";
    destination = "/bin/dunst-play-notification-sound";
    executable = true;
    text = builtins.readFile ./scripts/dunst-play-notification-sound.sh;
  };
in {
  config = lib.mkIf cfg.enable {
    # so it propagates to:
    # /run/current-system/sw/share/icons/Numix-Square
    environment.systemPackages = with pkgs; [ numix-icon-theme-square ];

    home-manager.users.${userName} = {
      home = {
        packages = with pkgs; [
          dunst
          dunst-play-notification-sound
          dunst-toggle-mode
          gnome-icon-theme
          libnotify
        ];
      };

      xdg.configFile = {
        "dunst/assets/notification.flac".source = ./assets/notification.flac;
        "dunst/dunstrc".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/dunstrc";
      };

      systemd.user.services.dunst = {
        Unit = {
          Description = "Lightweight and customizable notification daemon";
          Documentation = "https://github.com/dunst-project/dunst";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          # PassEnvironment = [ "XCURSOR_THEME" "XCURSOR_SIZE" ];
          ExecStart = "${pkgs.dunst}/bin/dunst";
          Restart = "on-failure";
          KillMode = "mixed";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
