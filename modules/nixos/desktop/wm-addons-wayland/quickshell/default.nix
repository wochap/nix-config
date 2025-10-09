{ config, pkgs, lib, inputs, ... }:

let
  cfg = config._custom.desktop.quickshell;
  inherit (config._custom.globals)
    themeColorsLight themeColorsDark preferDark configDirectory userName;
  hmConfig = config.home-manager.users.${userName};

  quickshell-final = inputs.quickshell.packages.${pkgs.system}.default;
  shell-capslock = pkgs.writeScriptBin "shell-capslock"
    (builtins.readFile ./scripts/shell-capslock.sh);
  shell-osd =
    pkgs.writeScriptBin "shell-osd" (builtins.readFile ./scripts/shell-osd.sh);
  shell-backlight = pkgs.writeScriptBin "shell-backlight"
    (builtins.readFile ./scripts/shell-backlight.sh);
  shell-hypr-ws-special-count =
    pkgs.writeScriptBin "shell-hypr-ws-special-count"
    (builtins.readFile ./scripts/shell-hypr-ws-special-count.sh);
  shell-network = pkgs.writeScriptBin "shell-network"
    (builtins.readFile ./scripts/shell-network.sh);
  shell-bluetooth = pkgs.writeScriptBin "shell-bluetooth"
    (builtins.readFile ./scripts/shell-bluetooth.sh);
  shell-idle-inhibit = pkgs.writeScriptBin "shell-idle-inhibit"
    (builtins.readFile ./scripts/shell-idle-inhibit.sh);
  shell-idle = pkgs.writeScriptBin "shell-idle"
    (builtins.readFile ./scripts/shell-idle.sh);
  shell-powerprofile = pkgs.writeScriptBin "shell-powerprofile"
    (builtins.readFile ./scripts/shell-powerprofile.sh);
  shell-lock = pkgs.writeScriptBin "shell-lock"
    (builtins.readFile ./scripts/shell-lock.sh);
  shell-steam-icons = pkgs.writeScriptBin "shell-steam-icons"
    (builtins.readFile ./scripts/shell-steam-icons.sh);
  shell-theme = pkgs.writeScriptBin "shell-theme"
    (builtins.readFile ./scripts/shell-theme.sh);
  mkThemeQuickshell = themeColors:
    pkgs.writeText "theme.json" (builtins.toJSON themeColors);
  catppuccin-quickshell-light-theme-path = mkThemeQuickshell themeColorsLight;
  catppuccin-quickshell-dark-theme-path = mkThemeQuickshell themeColorsDark;
in {
  options._custom.desktop.quickshell = {
    enable = lib.mkEnableOption { };
    systemdEnable = lib.mkEnableOption { };
    package = lib.mkOption {
      type = lib.types.package;
      default = quickshell-final;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # quickshell deps
      cfg.package
      kdePackages.qt5compat

      # shell deps
      ddcutil # query monitor
      rink # calculator
      wallust # pywall like
      matugen # color generator
    ];

    fonts.packages = with pkgs; [ nixpkgs-unstable.material-symbols ];

    _custom.hm = {
      home.packages = with pkgs; [
        shell-capslock
        shell-hypr-ws-special-count
        shell-network
        shell-bluetooth
        shell-idle-inhibit
        shell-idle
        shell-powerprofile
        shell-backlight
        shell-osd
        shell-lock
        shell-steam-icons
        shell-theme
      ];

      xdg.configFile = {
        "quickshell/shell".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/shell;
        "quickshell/theme.json" = {
          source = if preferDark then
            catppuccin-quickshell-dark-theme-path
          else
            catppuccin-quickshell-light-theme-path;
          force = true;
        };
        "quickshell/theme-light.json".source =
          catppuccin-quickshell-light-theme-path;
        "quickshell/theme-dark.json".source =
          catppuccin-quickshell-dark-theme-path;
      };

      # Install custom icon theme
      xdg.dataFile."icons/Reversal-Extra".source = "${inputs.reversal-extra}";

      systemd.user.services.shell = lib.mkIf cfg.systemdEnable
        (lib._custom.mkWaylandService {
          Unit = {
            Description =
              "Flexible toolkit for making desktop shells with QtQuick, for Wayland and X11";
            Documentation = "https://github.com/quickshell-mirror/quickshell";
          };
          Service = {
            Environment = [
              # NOTE: this or use `dbus-update-activation-environment --systemd <env_var_name>`
              "TIMEWARRIORDB=${hmConfig.home.sessionVariables.TIMEWARRIORDB}"
            ];
            PassEnvironment = [ "HYPRLAND_INSTANCE_SIGNATURE" ];
            ExecStart =
              "${quickshell-final}/bin/quickshell -p ${hmConfig.xdg.configHome}/quickshell/shell";
            Restart = "on-failure";
            KillMode = "mixed";
          };
        });
    };
  };
}
