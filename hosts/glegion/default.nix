{ config, ... }:

let
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
in {
  imports = [ ./hardware-configuration.nix ./hardware.nix ];

  config = {
    _custom.globals.userName = userName;
    _custom.globals.homeDirectory = "/home/${userName}";
    _custom.globals.configDirectory = configDirectory;

    # dev
    _custom.dev.lang-c.enable = true;
    _custom.dev.lang-go.enable = true;
    _custom.dev.lang-nix.enable = true;
    _custom.dev.lang-python.enable = true;
    _custom.dev.lang-ruby.enable = true;
    _custom.dev.lang-web.enable = true;

    _custom.programs.weeb.enable = true;

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
    _custom.programs.bat.enable = true;
    _custom.programs.buku.enable = true;
    _custom.programs.cht.enable = true;
    _custom.programs.dircolors.enable = true;
    _custom.programs.fzf.enable = true;
    _custom.programs.git.enable = true;
    _custom.programs.git.enableUser = true;
    _custom.programs.lsd.enable = true;
    _custom.programs.ptsh.enable = true;
    _custom.programs.zoxide.enable = true;
    _custom.programs.zsh.enable = true;
    _custom.programs.zsh.isDefault = true;

    # gui
    _custom.programs.alacritty.enable = false;
    _custom.programs.discord.enable = true;
    _custom.programs.firefox.enable = true;
    _custom.programs.foot.enable = true;
    _custom.programs.foot.systemdEnable = true;
    _custom.programs.foot.settings.main = {
      initial-window-size-pixels = "1440x900";
      workers = 8;
    };
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
    _custom.programs.neovim.enable = true;
    _custom.programs.newsboat.enable = true;
    _custom.programs.nnn.enable = true;
    _custom.programs.presenterm.enable = true;
    _custom.programs.taskwarrior.enable = true;
    _custom.programs.tmux.enable = true;
    _custom.programs.tmux.systemdEnable = true;
    _custom.programs.youtube.enable = true;

    _custom.services.android.enable = true;
    _custom.services.android.sdk.enable = false;
    _custom.services.docker.enable = true;
    _custom.services.docker.enableNvidia = true;
    _custom.services.flatpak.enable = false;
    _custom.services.interception-tools.enable = true;
    _custom.services.ipwebcam.enable = true;
    _custom.services.llm.enable = true;
    _custom.services.llm.enableNvidia = true;
    _custom.services.syncthing.enable = true;
    _custom.services.virt.enable = true;
    _custom.services.waydroid.enable = false;

    _custom.gaming.emulators.enable = true;
    _custom.gaming.steam.enable = true;
    _custom.gaming.utils.enable = true;

    _custom.desktop.power-management.cpupowerGuiArgs =
      [ "--performance" "profile" "Performance" ];
    _custom.desktop.ags.mainOutputName = "eDP-1";
    _custom.desktop.greetd.enable = true;
    _custom.desktop.greetd.enablePamAutoLogin = true;
    _custom.desktop.udev-rules.enable = true;
    _custom.desktop.dwl.enable = true;
    _custom.desktop.dwl.isDefault = true;
    _custom.desktop.hyprland.enable = true;
    _custom.archetypes.wm-wayland-desktop.enable = true;

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

