{ config, pkgs, lib, ... }:

let
  cfg = config._custom.waylandWm;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.lib.file) mkOutOfStoreSymlink;
  configDirectory = config._configDirectory;
  currentDirectory = "${configDirectory}/modules/wayland-wm/mixins/wob";
  wob-osd = pkgs.writeTextFile {
    name = "wob-osd";
    destination = "/bin/wob-osd";
    executable = true;
    text = builtins.readFile ./scripts/wob-osd.sh;
  };
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${userName} = {
      home = { packages = with pkgs; [ wob wob-osd ]; };

      xdg.configFile = {
        "wob/wob.ini".source =
          mkOutOfStoreSymlink "${currentDirectory}/dotfiles/wob.ini";
      };

      systemd.user = {
        services.wob = {
          Unit = {
            Description =
              "A lightweight overlay volume/backlight/progress/anything bar for Wayland";
            Documentation = "man:wob(1)";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
            ConditionEnvironment = [ "WAYLAND_DISPLAY" ];
          };

          Service = {
            ExecStart = "${pkgs.wob}/bin/wob";
            StandardInput = "socket";
          };

          Install = { WantedBy = [ "graphical-session.target" ]; };
        };

        sockets.wob = {
          Socket = {
            ListenFIFO = "%t/wob.sock";
            SocketMode = "0600";
            RemoveOnStop = "on";
            # If wob exits on invalid input, systemd should NOT shove following input right back into it after it restarts
            FlushPending = "yes";
          };

          Install = { WantedBy = [ "sockets.target" ]; };
        };
      };
    };
  };
}
