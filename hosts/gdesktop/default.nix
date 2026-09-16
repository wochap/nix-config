{ config, ... }:

let
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
in
{
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    ./hardware.nix
  ];

  config = {
    _custom.globals.userName = userName;
    _custom.globals.homeDirectory = "/home/${userName}";
    _custom.globals.configDirectory = configDirectory;
    _custom.globals.preferDark = true;

    _custom.archetypes.wm-wayland-desktop.enable = true;

    _custom.programs.weeb.enable = true;

    # cli
    _custom.programs.core-utils-extra-linux.enable = true;
    _custom.programs.core-utils-linux.enable = true;
    _custom.programs.nix-direnv.enable = true;

    # gui
    _custom.programs.dolphin.enable = true;
    _custom.programs.dolphin.daemonEnable = true;
    _custom.programs.electron.enable = true;
    _custom.programs.gtk.enable = true;
    # _custom.desktop.gtk.bookmarks = [ "file:///mnt/storage Storage" ];
    _custom.programs.imv.enable = true;
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
    _custom.programs.core-utils-extra.enable = true;
    _custom.programs.core-utils.enable = true;
    _custom.programs.dircolors.enable = true;
    _custom.programs.fzf.enable = true;
    _custom.programs.git.enable = true;
    _custom.programs.git.settings = {
      user = {
        email = config._custom.globals.secrets.personal.email;
        name = "wochap";
        signingKey = config._custom.globals.secrets.personal.email;
      };
      commit.gpgSign = true;
      core.sshCommand = "ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes";
    };
    _custom.programs.lazygit.enable = true;
    _custom.programs.lsd.enable = true;
    _custom.programs.ptsh.enable = true;
    # _custom.programs.rod.enable = true;
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
    _custom.programs.foot.enableSystemd = true;
    _custom.programs.foot.settings.main = {
      initial-window-size-pixels = "1920x1080";
      workers = 12;
    };
    _custom.programs.kitty.enable = true;
    _custom.programs.kitty.enableSystemd = true;
    _custom.programs.mpv.enable = true;
    _custom.programs.qutebrowser.enable = true;
    _custom.programs.vscode.enable = false;

    # tui
    _custom.programs.amfora.enable = true;
    _custom.programs.btop.enable = true;
    _custom.programs.less.enable = true;
    _custom.programs.lynx.enable = true;
    _custom.programs.neovim.enable = true;
    _custom.programs.newsboat.enable = true;
    _custom.programs.presenterm.enable = true;
    _custom.programs.taskwarrior.enable = true;
    _custom.programs.tmux.enable = true;
    _custom.programs.tmux.enableSystemd = true;
    _custom.programs.urlscan.enable = true;
    _custom.programs.yazi.enable = true;
    _custom.programs.youtube.enable = true;
    _custom.programs.zellij.enable = true;
    _custom.programs.ai-agents.enable = true;
    # _custom.programs.ai-agents.enableHandy = true;
    _custom.programs.ai-agents.sessionTap = {
      enable = true;
      sourceId = "gdesktop";
      sourceName = "gdesktop";
      enableHub = true;
    };

    _custom.services.android.enable = true;
    _custom.services.android.enableSdk = false;
    _custom.services.podman.enable = true;
    _custom.services.podman.rootless = true;
    _custom.services.podman.dockerCompat = true;
    _custom.services.docker.enable = false;
    _custom.services.interception-tools.enable = true;
    _custom.services.ipwebcam.enable = false;
    _custom.services.kdeconnect.enable = true;
    _custom.services.ai.enable = true;
    _custom.services.ai.enableRocm = true;
    _custom.services.ai.enableOllama = true;
    # _custom.services.ai.enableOcr = true;
    # _custom.services.ai.enableOllamaFlashAttention = true;
    # _custom.services.ai.enableNextjsOllamaLlmUi = false;
    # _custom.services.ai.enableOpenWebui = true;
    _custom.services.ai.enableSupertonic = true;
    # _custom.services.ai.enableQwen3Asr = true;
    _custom.services.ai.enableOmniRoute = true;
    _custom.services.ai.enableFirecrawl = true;
    # _custom.services.ai.enableGptResearcher = true;
    _custom.services.ai.enableArticleSummary = true;
    # _custom.services.ms-intune.enable = false;
    _custom.services.rsshub.enable = true;
    _custom.services.searxng.enable = true;

    _custom.services.syncthing.enable = true;
    _custom.services.virt.enable = false;

    _custom.gaming.emulators.enable = false;
    _custom.gaming.steam.enable = true;
    _custom.gaming.utils.enable = true;

    _custom.security.gpg.enableLuksIntegration = true;
    _custom.security.gpg.enableGpgAgent = true;
    _custom.security.gnome-keyring.enable = true;
    _custom.security.gnome-keyring.enableSshAgent = true;
    _custom.security.gnome-keyring.enableLuksIntegration = true;
    _custom.security.kwallet.enable = false;

    _custom.system.apple.enable = false;
    _custom.system.windows.enable = true;
    _custom.system.windows.enableSamba = false;
    _custom.system.user.password = "$6$rvioLchC4DiAN732$Me4ZmdCxRy3bacz/eGfyruh5sVVY2wK5dorX1ALUs2usXMKCIOQJYoGZ/qKSlzqbTAu3QHh6OpgMYgQgK92vn.";

    _custom.desktop.greetd.enable = true;
    _custom.desktop.greetd.enableAutoLogin = true;
    _custom.desktop.greetd.enableLuksIntegration = true;

    _custom.desktop.hyprland.enable = true;
    _custom.desktop.hyprland.isDefault = true;

    _custom.desktop.mail.enable = true;
    _custom.desktop.mail.accounts.personal = {
      primary = true;
      flavor = "gmail.com";
      address = config._custom.globals.secrets.personal.email;
      name = "Personal";
      passwordSecret.sopsFile = ../../secrets-sops/personal.yaml;
      passwordSecret.sopsKey = "personal-mail-password";
      sync = "lieer";
      inboxKey = "P";
      color = "red";
      pgpKey = "E73095E1";
      signatureLines = [
        [
          "Gean Marroquin"
          "Software Product Consultant"
        ]
        [ "https://geanmar.com" ]
        [ "GPG: E73095E1" ]
      ];
      virtualFolders = [
        {
          name = "gmail";
          query = "from:*@gmail.com";
        }
      ];
      # hooks.arrive = [
      #   {
      #     from = "*@gmail.com";
      #     command = "";
      #   }
      # ];
    };

    _custom.desktop.calendar.accounts.personal = {
      name = "personal";
      primary = true;
      primaryCollection = config._custom.globals.secrets.personal.email;
    };

    _custom.desktop.contacts.enable = true;
    _custom.desktop.contacts.accounts.personal = {
      name = "personal";
    };

    _custom.desktop.backlight.enable = false;
    _custom.desktop.home-screen.enable = true;
    _custom.desktop.audio.enableEasyeffects = true;
    _custom.desktop.audio.enableNoisetorch = true;
    _custom.desktop.mouseless.enable = true;
    _custom.desktop.networking.enableWifi = true;
    _custom.desktop.networking.enableLocalSend = true;
    _custom.desktop.networking.enableOpenSnitch = true;
    _custom.desktop.plymouth.enable = false;
    _custom.desktop.power-management.cpupowerGui.enable = true;
    _custom.desktop.power-management.cpupowerGui.args = [
      "--performance"
      "profile"
      "Performance"
    ];
    _custom.desktop.udev-rules.enable = true;
    _custom.desktop.hyprsunset.enable = true;
    # fix blurry cursor on GTK 3 apps
    # update catppuccin cursor NOMINAL_SIZE
    # TODO: remove after updating gtk to 4.18
    # source: https://blogs.kde.org/2024/10/09/cursor-size-problems-in-wayland-explained/#my-fix-or-shall-we-say-workaround
    # source: https://gitlab.gnome.org/GNOME/gtk/-/merge_requests/7722
    # source: https://bbs.archlinux.org/viewtopic.php?id=299624
    _custom.desktop.cursor.name = "catppuccin-mocha-dark-cursors";
    _custom.desktop.cursor.size = 24;

    _custom.sandbox.enable = false;

    # Setup keyboard
    services.xserver.xkb = {
      layout = "us";
      model = "pc104";
      variant = "";
      options = "compose:ralt";
    };

    time.timeZone = "America/Panama";

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "26.05"; # Did you read the comment?

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    home-manager.users.${userName}.home.stateVersion = "26.05";
  };
}
