{ config, pkgs, ... }:

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

    # fix blurry cursor on GTK 3 apps
    # update catppuccin cursor NOMINAL_SIZE
    # TODO: remove after updating gtk to 4.18
    # source: https://blogs.kde.org/2024/10/09/cursor-size-problems-in-wayland-explained/#my-fix-or-shall-we-say-workaround
    # source: https://gitlab.gnome.org/GNOME/gtk/-/merge_requests/7722
    # source: https://bbs.archlinux.org/viewtopic.php?id=299624
    _custom.globals.cursor.package =
      pkgs.catppuccin-cursors.mochaDark.overrideAttrs (oldAttrs: rec {
        patches = [
          (pkgs.fetchpatch {
            url =
              "https://github.com/wochap/cursors/commit/243becf94ad2ae52eb8be55fc36f329ca7f2ce3b.patch";
            sha256 = "sha256-fQnE9HHRG8PoNGAeax+KAeWV8XR81jwVAJ3Yrt7UYQc=";
          })
        ];
      });
    _custom.globals.cursor.size = 28;

    _custom.programs.weeb.enable = true;

    # cli
    _custom.programs.core-utils-extra-linux.enable = true;
    _custom.programs.core-utils-linux.enable = true;
    _custom.programs.nix-direnv.enable = true;

    # gui
    _custom.programs.dolphin.enable = true;
    _custom.programs.electron.enable = true;
    _custom.programs.gtk.enable = true;
    _custom.programs.imv.enable = true;
    _custom.programs.imv.enableInsecureFreeImage = true;
    _custom.programs.mongodb.enable = true;
    _custom.programs.obs-studio.enable = true;
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
    _custom.programs.core-utils-extra.enable = true;
    _custom.programs.core-utils.enable = true;
    _custom.programs.dircolors.enable = true;
    _custom.programs.fzf.enable = true;
    _custom.programs.git.enable = true;
    _custom.programs.git.enableUser = true;
    _custom.programs.lsd.enable = true;
    _custom.programs.ptsh.enable = true;
    _custom.programs.texlive.enable = true;
    _custom.programs.zk.enable = true;
    _custom.programs.zoxide.enable = true;
    _custom.programs.zsh.enable = true;
    # tmux and kitty still use zsh
    _custom.programs.zsh.isDefault = false;

    # dev
    _custom.programs.lang-c.enable = true;
    _custom.programs.lang-go.enable = true;
    _custom.programs.lang-lua.enable = true;
    _custom.programs.lang-nix.enable = true;
    _custom.programs.lang-python.enable = true;
    _custom.programs.lang-qt.enable = true;
    _custom.programs.lang-ruby.enable = true;
    _custom.programs.lang-rust.enable = true;
    _custom.programs.lang-web.enable = true;
    _custom.programs.tools.enable = true;

    # gui
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
    _custom.programs.urlscan.enable = true;
    _custom.programs.youtube.enable = true;

    _custom.services.android.enable = true;
    _custom.services.android.sdk.enable = false;
    _custom.services.docker.enable = true;
    _custom.services.docker.enableNvidia = true;
    _custom.services.flatpak.enable = false;
    _custom.services.interception-tools.enable = true;
    _custom.services.ipwebcam.enable = true;
    _custom.services.kdeconnect.enable = true;
    _custom.services.ai.enable = true;
    _custom.services.ai.enableWhisper = true;
    _custom.services.ai.enablePix2tex = true;
    _custom.services.ai.enableOllama = true;
    _custom.services.ai.enableNvidia = true;
    _custom.services.ai.enableOllamaWebuiLite = false;
    _custom.services.ai.enableNextjsOllamaLlmUi = false;
    _custom.services.ai.enableOpenWebui = true;
    _custom.services.syncthing.enable = true;
    _custom.services.virt.enable = true;
    _custom.services.waydroid.enable = false;

    _custom.gaming.emulators.enable = true;
    _custom.gaming.steam.enable = true;
    _custom.gaming.utils.enable = true;

    _custom.system.apple.enable = false;
    _custom.system.windows.enable = true;
    _custom.system.windows.enableSamba = false;

    _custom.desktop.plymouth.enable = false;
    _custom.desktop.xwaylandvideobridge.enable = false;
    _custom.desktop.power-management.cpupowerGuiArgs =
      [ "--performance" "profile" "Performance" ];
    _custom.desktop.power-management.keyboard = {
      enable = true;
      idVendor = "048d";
      idProduct = "c104";
    };
    _custom.desktop.greetd.enable = true;
    _custom.desktop.greetd.enablePamAutoLogin = true;
    _custom.desktop.udev-rules.enable = true;
    _custom.desktop.udev-rules.canDisableGlegionKbd = false;
    _custom.desktop.gammastep.enable = false;
    _custom.desktop.hyprsunset.enable = true;
    _custom.desktop.wluma.enable = false;
    _custom.desktop.wluma.systemdEnable = true;
    _custom.desktop.wluma.config.als.none = { };
    _custom.desktop.wluma.config.output.backlight = [{
      name = "Samsung Display Corp. 0x4188 Unknown";
      path = "/sys/class/backlight/amdgpu_bl1";
      capturer = "wayland";
    }];
    _custom.desktop.dwl.enable = false;
    _custom.desktop.dwl.isDefault = false;
    _custom.desktop.hyprland.enable = true;
    _custom.desktop.hyprland.isDefault = true;
    _custom.archetypes.wm-wayland-desktop.enable = true;

    # Setup keyboard
    services.xserver.xkb = {
      layout = "us";
      model = "pc104";
      variant = "";
      options = "compose:ralt";
    };

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

