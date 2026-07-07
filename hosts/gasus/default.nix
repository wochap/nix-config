{ config, pkgs, ... }:

let
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
in {
  imports =
    [ ./hardware-configuration.nix ./disk-configuration.nix ./hardware.nix ];

  config = {
    _custom.globals.userName = userName;
    _custom.globals.homeDirectory = "/home/${userName}";
    _custom.globals.configDirectory = configDirectory;
    _custom.globals.preferDark = true;

    # _custom.programs.weeb.enable = true;

    # cli
    _custom.programs.core-utils-extra-linux.enable = true;
    _custom.programs.core-utils-linux.enable = true;
    _custom.programs.nix-direnv.enable = true;

    # gui
    # _custom.programs.dolphin.enable = true;
    # _custom.programs.electron.enable = true;
    # _custom.programs.gtk.enable = true;
    # _custom.programs.imv.enable = true;
    # _custom.programs.imv.enableInsecureFreeImage = true;
    # _custom.programs.mongodb.enable = true;
    # _custom.programs.obs-studio.enable = true;
    # _custom.programs.thunar.enable = true;
    # _custom.programs.qt.enable = true;
    # _custom.programs.zathura.enable = true;

    # _custom.programs.others-linux.enable = true;

    # tui
    # _custom.programs.figlet.enable = true;
    # _custom.programs.fontpreview-kik.enable = true;

    # cli
    _custom.programs.bat.enable = true;
    # _custom.programs.buku.enable = true;
    _custom.programs.cht.enable = true;
    _custom.programs.core-utils-extra.enable = true;
    _custom.programs.core-utils.enable = true;
    _custom.programs.dircolors.enable = true;
    _custom.programs.fzf.enable = true;
    _custom.programs.git.enable = true;
    _custom.programs.git.enableUser = true;
    _custom.programs.lazygit.enable = true;
    _custom.programs.lsd.enable = true;
    _custom.programs.ptsh.enable = true;
    _custom.programs.rod.enable = true;
    # _custom.programs.texlive.enable = true;
    # _custom.programs.zk.enable = true;
    _custom.programs.zoxide.enable = true;
    _custom.programs.zsh.enable = true;
    # tmux and kitty still use zsh
    _custom.programs.zsh.isDefault = false;

    # dev
    # _custom.programs.lang-c.enable = true;
    # _custom.programs.lang-go.enable = true;
    # _custom.programs.lang-lua.enable = true;
    _custom.programs.lang-nix.enable = true;
    # _custom.programs.lang-python.enable = true;
    # _custom.programs.lang-qt.enable = true;
    # _custom.programs.lang-ruby.enable = true;
    # _custom.programs.lang-rust.enable = true;
    # _custom.programs.lang-web.enable = true;
    _custom.programs.tools.enable = true;

    # gui
    # _custom.programs.discord.enable = true;
    # _custom.programs.firefox.enable = true;
    # _custom.programs.foot.enable = true;
    # _custom.programs.foot.systemdEnable = true;
    # _custom.programs.foot.settings.main = {
    #   initial-window-size-pixels = "1440x900";
    #   workers = 8;
    # };
    # _custom.programs.kitty.enable = true;
    # _custom.programs.mpv.enable = true;
    # _custom.programs.qutebrowser.enable = true;
    # _custom.programs.vscode.enable = true;

    # tui
    # _custom.programs.amfora.enable = true;
    _custom.programs.bottom.enable = true;
    _custom.programs.less.enable = true;
    # _custom.programs.lynx.enable = true;
    _custom.programs.neovim.enable = true;
    # _custom.programs.newsboat.enable = true;
    _custom.programs.nnn.enable = true;
    # _custom.programs.presenterm.enable = true;
    # _custom.programs.taskwarrior.enable = true;
    _custom.programs.tmux.enable = true;
    _custom.programs.tmux.systemdEnable = true;
    _custom.programs.urlscan.enable = true;
    _custom.programs.youtube.enable = true;

    # _custom.services.android.enable = true;
    # _custom.services.android.sdk.enable = false;
    _custom.services.docker.enable = true;
    _custom.services.docker.enableNvidia = false;
    # _custom.services.flatpak.enable = false;
    # _custom.services.interception-tools.enable = true;
    # _custom.services.ipwebcam.enable = true;
    # _custom.services.kdeconnect.enable = true;
    # _custom.services.ai.enable = false;
    # _custom.services.ms-intune.enable = false;

    # _custom.services.syncthing.enable = false;
    # _custom.services.virt.enable = false;
    # _custom.services.waydroid.enable = false;

    # _custom.gaming.emulators.enable = false;
    # _custom.gaming.steam.enable = false;
    # _custom.gaming.utils.enable = false;

    # _custom.system.apple.enable = false;
    # _custom.system.windows.enable = false;
    # _custom.system.windows.enableSamba = false;

    _custom.desktop.networking.localSendEnable = true;
    # _custom.desktop.plymouth.enable = false;
    # _custom.desktop.xwaylandvideobridge.enable = false;
    _custom.desktop.power-management.cpupowerGuiArgs =
      [ "--performance" "profile" "Performance" ];
    # _custom.desktop.power-management.keyboard = {
    #   enable = true;
    #   idVendor = "048d";
    #   idProduct = "c104";
    # };
    # _custom.desktop.greetd.enable = true;
    # _custom.desktop.greetd.enableAutoLogin = false;
    # _custom.desktop.greetd.enablePamAutoLogin = false;
    # _custom.desktop.udev-rules.enable = false;
    # _custom.desktop.udev-rules.canDisableGlegionKbd = false;
    # _custom.desktop.gammastep.enable = false;
    # _custom.desktop.hyprsunset.enable = false;
    # _custom.desktop.wluma.enable = false;
    # _custom.desktop.hyprland.enable = false;
    # _custom.desktop.hyprland.isDefault = false;
    _custom.archetypes.server.enable = false;
    # _custom.security.gnome-keyring.enable = true;
    # _custom.security.kwallet.enable = false;

    # Setup keyboard
    # services.xserver.xkb = {
    #   layout = "us";
    #   model = "pc104";
    #   variant = "";
    #   options = "compose:ralt";
    # };

    # Enable touchpad support (enabled default in most desktopManager).
    services.libinput = {
      enable = true;
      touchpad.naturalScrolling = true;
      touchpad.tapping = true;
    };

    time.timeZone = "America/Panama";

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "25.05"; # Did you read the comment?

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    home-manager.users.${userName}.home.stateVersion = "25.05";
  };
}

