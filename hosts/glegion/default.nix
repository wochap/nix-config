{ config, ... }:

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

    _custom.security.doas.enable = true;
    _custom.security.gnome-keyring.enable = true;
    _custom.security.gpg.enable = true;
    _custom.security.polkit.enable = true;
    _custom.security.ssh.enable = true;

    _custom.cli.asciinema.enable = true;
    _custom.cli.bat.enable = true;
    _custom.cli.buku.enable = true;
    _custom.cli.cht.enable = true;
    _custom.cli.git.enable = true;
    _custom.cli.nix-alien.enable = true;
    _custom.cli.nix-direnv.enable = true;
    _custom.cli.ptsh.enable = true;
    _custom.cli.zsh.enable = true;
    _custom.cli.zsh.isDefault = true;
    _custom.cli.dircolors.enable = true;
    _custom.cli.fzf.enable = true;
    _custom.cli.lsd.enable = true;
    _custom.cli.starship.enable = true;
    _custom.cli.youtube.enable = true;
    _custom.cli.zoxide.enable = true;

    _custom.tui.amfora.enable = true;
    _custom.tui.fontpreview-kik.enable = true;
    _custom.tui.lynx.enable = true;
    _custom.tui.mangadesk.enable = true;
    _custom.tui.mangal.enable = true;
    _custom.tui.neovim.enable = true;
    _custom.tui.newsboat.enable = true;
    _custom.tui.nnn.enable = true;
    _custom.tui.taskwarrior.enable = true;
    _custom.tui.bottom.enable = true;

    _custom.gui.alacritty.enable = true;
    _custom.gui.discord.enable = true;
    _custom.gui.firefox.enable = true;
    _custom.gui.kitty.enable = true;
    _custom.gui.mpv.enable = true;
    _custom.gui.qutebrowser.enable = true;
    _custom.gui.retroarch.enable = true;
    _custom.gui.thunar.enable = true;
    _custom.gui.vscode.enable = true;
    _custom.gui.zathura.enable = true;
    _custom.gui.imv.enable = true;
    _custom.programs.mongodb.enable = true;
    _custom.programs.gtk.enable = true;
    _custom.programs.qt.enable = true;
    _custom.programs.nodejs.enable = true;
    _custom.programs.python.enable = true;
    _custom.programs.suites.enable = true;
    _custom.programs.suites-linux.enable = true;

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

    _custom.de.audio.enable = true;
    _custom.de.backlight.enable = true;
    _custom.de.bluetooth.enable = true;
    _custom.de.calendar.enable = true;
    _custom.de.cursor.enable = true;
    _custom.de.dbus.enable = true;
    _custom.de.email.enable = true;
    _custom.de.fonts.enable = true;
    _custom.de.gtk.enable = true;
    _custom.de.logind.enable = true;
    _custom.de.music.enable = true;
    _custom.de.neofetch.enable = true;
    _custom.de.networking.enable = true;
    _custom.de.plymouth.enable = true;
    _custom.de.power-management.enable = true;
    _custom.de.power-management.enableLowBatteryNotification = true;
    _custom.de.qt.enable = true;
    _custom.de.xdg.enable = true;

    _custom.de.cliphist.enable = true;
    _custom.de.dunst.enable = true;
    _custom.de.gammastep.enable = true;
    _custom.de.kanshi.enable = true;
    _custom.de.swayidle.enable = true;
    _custom.de.swaylock.enable = true;
    _custom.de.swww.enable = true;
    _custom.de.tofi.enable = true;
    _custom.de.utils.enable = true;
    _custom.de.waybar.enable = true;
    _custom.de.wayland-session.enable = true;
    _custom.de.wob.enable = true;

    _custom.de.kde.enable = false;
    _custom.de.gnome.enable = false;
    _custom.de.greetd.enable = true;
    _custom.de.gdm.enable = false;
    _custom.de.dwl.enable = true;
    _custom.de.dwl.isDefault = true;
    _custom.de.river.enable = false;
    _custom.de.hyprland.enable = false;
    _custom.de.sway.enable = false;

    services.xserver = {
      # Setup keyboard
      layout = "us";
      xkbModel = "pc104";
      xkbVariant = "";

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
    home-manager.users.${userName} = {
      home.stateVersion = "23.11";

      # programs.waybar.settings.mainBar."modules-right" = lib.mkForce [
      #   "tray"
      #   "custom/recorder"
      #   "idle_inhibitor"
      #   "custom/notifications"
      #   "custom/offlinemsmtp"
      #   "temperature"
      #   "pulseaudio"
      #   "bluetooth"
      #   "network"
      #   "clock"
      # ];

      # programs.waybar.settings.mainBar = {
      #   temperature = {
      #     hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon";
      #     input-filename = "temp1_input";
      #   };
      #   keyboard-state = { device-path = "/dev/input/event25"; };
      # };
    };
  };
}

