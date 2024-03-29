{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.waybar;
  inherit (config._custom.globals) themeColors configDirectory;
  waybar = pkgs.stable.waybar;
  jsonRAW = builtins.readFile ./dotfiles/config.json;
  parsedJson = builtins.fromJSON jsonRAW;
  waybar-toggle = pkgs.writeScriptBin "waybar-toggle"
    (builtins.readFile ./scripts/waybar-toggle.sh);
in {
  options._custom.desktop.waybar = {
    enable = lib.mkEnableOption { };
    systemdEnable = lib.mkEnableOption { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ libevdev ];

    _custom.hm = {
      disabledModules = [ "programs/waybar.nix" ];
      imports = [ ./options.nix ];

      home.packages = [ waybar waybar-toggle ];

      # edited waybar module, only generates $HOME/waybar/config and nothing else
      programs.waybar = {
        enable = true;
        settings.mainBar = parsedJson;
      };

      xdg.configFile = {
        "waybar/style.css".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/style.css;
        "waybar/colors.css".text = ''
          ${lib.concatStringsSep "\n" (lib.attrsets.mapAttrsToList
            (key: value: "@define-color ${key} ${value};") themeColors)}
        '';
      };

      systemd.user.services.waybar = lib.mkIf cfg.systemdEnable
        (lib._custom.mkWaylandService {
          Unit = {
            Description =
              "Highly customizable Wayland bar for Sway and Wlroots based compositors.";
            Documentation = "https://github.com/Alexays/Waybar/wiki";
          };
          Service = {
            PassEnvironment = "PATH";
            ExecStart = "${waybar}/bin/waybar";
            ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
            Restart = "on-failure";
            KillMode = "mixed";
          };
        });
    };
  };
}
