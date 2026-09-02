{ config, pkgs, ... }:

let
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
in
{
  imports = [
    ./hardware-configuration.nix
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
    _custom.programs.electron.enable = true;
    _custom.programs.gtk.enable = true;
    _custom.desktop.gtk.bookmarks = [ "file:///mnt/storage Storage" ];
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
    _custom.programs.git.includes = [
      {
        condition = "gitdir:~/Projects/se/**/.git";
        contents = {
          user = {
            email = config._custom.globals.secrets.se.email;
            name = "Gean";
            signingKey = config._custom.globals.secrets.se.email;
          };
          commit.gpgSign = true;
          core.sshCommand = "ssh -i ~/.ssh/id_ed25519_se -o IdentitiesOnly=yes";
        };
      }
    ];
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
      initial-window-size-pixels = "1440x900";
      workers = 8;
    };
    _custom.programs.kitty.enable = true;
    _custom.programs.kitty.enableSystemd = true;
    _custom.programs.mpv.enable = true;
    _custom.programs.qutebrowser.enable = true;
    _custom.programs.vscode.enable = true;

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
    _custom.programs.ai-agents.enableHandy = true;
    _custom.programs.ai-agents.sessionTap = {
      enable = true;
      sourceId = "host";
      sourceName = "Host";
      hubUrl = "http://127.0.0.1:8931/ingest";
      enableHub = true;
    };

    _custom.services.android.enable = true;
    _custom.services.podman.enable = true;
    _custom.services.podman.rootless = true;
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
    _custom.services.ai.enableOllamaFlashAttention = true;
    _custom.services.ai.enableNvidia = true;
    _custom.services.ai.enableNextjsOllamaLlmUi = false;
    _custom.services.ai.enableOpenWebui = true;
    _custom.services.ai.enableSupertonic = true;
    _custom.services.ai.enableQwen3Asr = true;
    _custom.services.ai.enableOmniRoute = true;
    _custom.services.ai.enableGptResearcher = true;
    _custom.services.ai.enableArticleSummary = true;
    _custom.services.ms-intune.enable = true;
    _custom.services.rsshub.enable = true;
    _custom.services.searxng.enable = true;

    _custom.services.syncthing.enable = true;
    _custom.services.virt.enable = false;
    _custom.services.waydroid.enable = false;

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
    _custom.desktop.hyprland.uwsmSessionVariables = {
      IGPU_CARD = "$(readlink -f /dev/dri/by-path/pci-0000:06:00.0-card)";
      DGPU_CARD = "$(readlink -f /dev/dri/by-path/pci-0000:01:00.0-card)";
      # Use iGPU for hyprland
      AQ_DRM_DEVICES = "$(readlink -f /dev/dri/by-path/pci-0000:06:00.0-card)";

      # Tells every app to use my iGPU unless I specially instruct it not to
      # I would have to use the `nvidia-offload` command
      # This also speeds up the startup time of apps using GPU, because my nvidia card is always powered off
      # source: https://sw.kovidgoyal.net/kitty/faq/#why-does-kitty-sometimes-start-slowly-on-my-linux-system
      # source: https://github.com/Einjerjar/nix/blob/172d17410cd0849f7028f80c0e2084b4eab27cc7/home/vars.nix#L30
      # source: https://github.com/NixOS/nixpkgs/pull/139354#issuecomment-926942682
      __EGL_VENDOR_LIBRARY_FILENAMES = "${config.hardware.graphics.package}/share/glvnd/egl_vendor.d/50_mesa.json:${config.hardware.nvidia.package}/share/glvnd/egl_vendor.d/10_nvidia.json";
      __GLX_VENDOR_LIBRARY_NAME = "mesa";

      # env variables for starting hyprland with discrete gpu
      # NOTE: This is specific to glegion host with nvidia
      # to enable using the HDMI port connected directly to the dGPU
      # export __EGL_VENDOR_LIBRARY_FILENAMES=
      # export AQ_DRM_DEVICES=$IGPU_CARD:$DGPU_CARD
    };

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
          "Software Engineer"
        ]
        [ "https://geanmar.com" ]
        [ "GPG: E73095E1" ]
      ];
      # hooks.arrive = [
      #   {
      #     from = "*@gmail.com";
      #     command = "";
      #   }
      # ];
    };
    _custom.desktop.mail.accounts.se = {
      flavor = "gmail.com";
      address = config._custom.globals.secrets.se.email;
      name = "SE";
      passwordSecret.sopsFile = ../../secrets-sops/se.yaml;
      passwordSecret.sopsKey = "se-mail-password";
      sync = "lieer";
      inboxKey = "S";
      color = "yellow";
      pgpKey = "00F9FB30";
      signatureLines = [ [ "GPG: 00F9FB30" ] ];
      # ALL pearson mails (read/unread), not only the ones in inbox
      virtualFolders = [
        {
          name = "pearson";
          query = "from:*@pearson.com";
        }
        {
          name = "jira mentions";
          query = ''from:*.atlassian.net and subject:"mentioned you on"'';
        }
        {
          name = "jira assigned";
          query = ''from:*.atlassian.net and subject:"/assigned.*to you$/"'';
        }
      ];
    };

    _custom.desktop.calendar.accounts.personal = {
      name = "personal";
      primary = true;
      primaryCollection = config._custom.globals.secrets.personal.email;
    };
    _custom.desktop.calendar.accounts.se = {
      name = "se";
    };

    _custom.desktop.contacts.enable = true;
    _custom.desktop.contacts.accounts.personal = {
      name = "personal";
    };
    _custom.desktop.contacts.accounts.se = {
      name = "se";
    };

    _custom.desktop.home-screen.enable = true;
    _custom.desktop.audio.enableEasyeffects = true;
    _custom.desktop.audio.enableNoisetorch = true;
    _custom.desktop.mouseless.enable = true;
    _custom.desktop.networking.enableWifi = true;
    _custom.desktop.networking.enableLocalSend = true;
    _custom.desktop.networking.enableOpenSnitch = true;
    _custom.desktop.plymouth.enable = false;
    _custom.desktop.xwaylandvideobridge.enable = false;
    _custom.desktop.power-management.cpupowerGui.enable = true;
    _custom.desktop.power-management.cpupowerGui.args = [
      "--performance"
      "profile"
      "Performance"
    ];
    _custom.desktop.power-management.keyboard = {
      enable = true;
      idVendor = "048d";
      idProduct = "c104";
    };
    _custom.desktop.udev-rules.enable = true;
    _custom.desktop.udev-rules.canDisableGlegionKbd = false;
    _custom.desktop.hyprsunset.enable = true;
    _custom.desktop.wluma.enable = false;
    _custom.desktop.wluma.enableSystemd = true;
    _custom.desktop.wluma.config.als.none = { };
    _custom.desktop.wluma.config.output.backlight = [
      {
        name = "Samsung Display Corp. 0x4188 Unknown";
        path = "/sys/class/backlight/amdgpu_bl1";
        capturer = "wayland";
      }
    ];
    # fix blurry cursor on GTK 3 apps
    # update catppuccin cursor NOMINAL_SIZE
    # TODO: remove after updating gtk to 4.18
    # source: https://blogs.kde.org/2024/10/09/cursor-size-problems-in-wayland-explained/#my-fix-or-shall-we-say-workaround
    # source: https://gitlab.gnome.org/GNOME/gtk/-/merge_requests/7722
    # source: https://bbs.archlinux.org/viewtopic.php?id=299624
    _custom.desktop.cursor.name = "catppuccin-mocha-dark-cursors";
    _custom.desktop.cursor.size = 24;

    _custom.sandbox.enable = true;
    _custom.sandbox.internetInterface = "wlan0";

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
