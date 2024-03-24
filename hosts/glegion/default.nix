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

    _custom.programs.others-linux.enable = true;

    # tui
    _custom.programs.figlet.enable = true;
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
    _custom.programs.vscode.enable = true;

    _custom.programs.others.enable = true;

    # tui
    _custom.programs.amfora.enable = true;
    _custom.programs.bottom.enable = true;
    _custom.programs.less.enable = true;
    _custom.programs.lynx.enable = true;
    _custom.programs.mangadesk.enable = true;
    _custom.programs.mangal.enable = true;
    _custom.programs.neovim.enable = true;
    _custom.programs.newsboat.enable = true;
    _custom.programs.nnn.enable = true;
    _custom.programs.taskwarrior.enable = true;
    _custom.programs.tmux.enable = true;
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
    _custom.services.syncthing.enable = true;
    _custom.services.virt.enable = false;
    _custom.services.waydroid.enable = false;

    _custom.gaming.emulators.enable = true;
    _custom.gaming.steam.enable = true;
    _custom.gaming.utils.enable = true;

    _custom.desktop.udev-rules.enable = true;
    _custom.desktop.greetd.enable = true;
    _custom.desktop.dwl.enable = true;
    _custom.desktop.dwl.isDefault = true;
    _custom.desktop.hyprland.enable = true;
    _custom.desktop.labwc.enable = true;
    _custom.archetypes.wm-wayland-desktop.enable = true;

    # specialisation.hyprland-specialisation = {
    #   inheritParentConfig = true;
    #   configuration.config = {
    #     _custom.desktop.dwl.enable = lib.mkForce false;
    #     _custom.desktop.hyprland.enable = true;
    #     _custom.desktop.hyprland.isDefault = true;
    #
    #     services.auto-epp.enable = lib.mkForce false;
    #   };
    # };

    services.xserver = {
      # Setup keyboard
      xkb.layout = "us";
      xkb.model = "pc104";
      xkb.variant = "";
      xkb.options = "compose:ralt";

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

