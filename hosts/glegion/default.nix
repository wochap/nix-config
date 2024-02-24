{ config, lib, ... }:

let
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
  catppuccinMochaTheme = import ../../modules/mixins/catppuccin-mocha.nix;
in {
  imports = [ ./hardware-configuration.nix ./hardware.nix ];

  config = {
    _custom.globals.userName = userName;
    _custom.globals.homeDirectory = "/home/${userName}";
    _custom.globals.configDirectory = configDirectory;
    _custom.globals.themeColors = catppuccinMochaTheme;

    # cli
    _custom.programs.nix-alien.enable = true;
    _custom.programs.nix-direnv.enable = true;

    # gui
    _custom.programs.gtk.enable = true;
    _custom.programs.imv.enable = true;
    _custom.programs.mongodb.enable = true;
    _custom.programs.thunar.enable = true;
    _custom.programs.qt.enable = true;
    _custom.programs.zathura.enable = true;

    _custom.programs.suites-linux.enable = true;

    # tui
    _custom.programs.fontpreview-kik.enable = true;

    # cli
    _custom.programs.asciinema.enable = true;
    _custom.programs.bat.enable = true;
    _custom.programs.buku.enable = true;
    _custom.programs.cht.enable = true;
    _custom.programs.dircolors.enable = true;
    _custom.programs.fzf.enable = true;
    _custom.programs.git.enable = true;
    _custom.programs.lsd.enable = true;
    _custom.programs.nodejs.enable = true;
    _custom.programs.ptsh.enable = true;
    _custom.programs.python.enable = true;
    _custom.programs.starship.enable = false;
    _custom.programs.zoxide.enable = true;
    _custom.programs.zsh.enable = true;
    _custom.programs.zsh.isDefault = true;

    # gui
    _custom.programs.alacritty.enable = true;
    _custom.programs.discord.enable = true;
    _custom.programs.firefox.enable = true;
    _custom.programs.kitty.enable = true;
    _custom.programs.mpv.enable = true;
    _custom.programs.qutebrowser.enable = true;
    _custom.programs.retroarch.enable = true;
    _custom.programs.vscode.enable = true;

    _custom.programs.suites.enable = true;

    # tui
    _custom.programs.amfora.enable = true;
    _custom.programs.bottom.enable = true;
    _custom.programs.lynx.enable = true;
    _custom.programs.mangadesk.enable = true;
    _custom.programs.mangal.enable = true;
    _custom.programs.neovim.enable = true;
    _custom.programs.newsboat.enable = true;
    _custom.programs.nnn.enable = true;
    _custom.programs.taskwarrior.enable = true;
    _custom.programs.youtube.enable = true;

    _custom.services.android.enable = true;
    _custom.services.android.sdk.enable = false;
    _custom.services.docker.enable = true;
    _custom.services.docker.enableNvidia = true;
    _custom.services.flatpak.enable = false;
    _custom.services.interception-tools.enable = true;
    _custom.services.ipwebcam.enable = false;
    _custom.services.llm.enable = true;
    _custom.services.llm.enableNvidia = true;
    _custom.services.steam.enable = true;
    _custom.services.syncthing.enable = true;
    _custom.services.virt.enable = true;
    _custom.services.waydroid.enable = false;

    _custom.de.greetd.enable = true;
    _custom.de.dwl.enable = true;
    _custom.de.dwl.isDefault = true;
    _custom.archetypes.wm-wayland-desktop.enable = true;

    specialisation = {
      # gnome-specialisation = {
      #   inheritParentConfig = true;
      #   configuration.config = {
      #     _custom.security.gnome-keyring.enable = true;
      #
      #     _custom.de.dwl.enable = lib.mkForce false;
      #     _custom.de.gnome.enable = lib.mkForce true;
      #     _custom.de.greetd.enable = lib.mkForce false;
      #
      #     _custom.archetypes.wm-wayland-desktop.enable = lib.mkForce false;
      #     _custom.archetypes.de-wayland-desktop.enable = true;
      #
      #     services.auto-epp.enable = lib.mkForce false;
      #   };
      # };

      kde-specialisation = {
        inheritParentConfig = true;
        configuration.config = {
          _custom.programs.gaming.enable = true;

          _custom.de.dwl.enable = lib.mkForce false;
          _custom.de.kde.enable = lib.mkForce true;
          _custom.de.greetd.enable = lib.mkForce false;
          _custom.de.audio.enable = true;
          _custom.de.bluetooth.enable = true;

          _custom.archetypes.wm-wayland-desktop.enable = lib.mkForce false;
          _custom.archetypes.de-wayland-desktop.enable = true;

          services.auto-epp.enable = lib.mkForce false;
        };
      };

      hyprland-specialisation = {
        inheritParentConfig = true;
        configuration.config = {
          _custom.programs.gaming.enable = true;

          _custom.de.dwl.enable = lib.mkForce false;
          _custom.de.hyprland.enable = true;
          _custom.de.hyprland.isDefault = true;

          services.auto-epp.enable = lib.mkForce false;
        };
      };
    };

    services.xserver = {
      # Setup keyboard
      layout = "us";
      xkbModel = "pc104";
      xkbVariant = "";
      xkbOptions = "compose:ralt";

      # Enable touchpad support (enabled default in most desktopManager).
      libinput.enable = true;
      libinput.touchpad.naturalScrolling = true;
      libinput.touchpad.tapping = true;
    };

    time.timeZone = "America/Panama";

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "23.11"; # Did you read the comment?

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    home-manager.users.${userName}.home.stateVersion = "23.11";
  };
}

