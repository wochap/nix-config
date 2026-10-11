{ config, lib, ... }:

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
    _custom.programs.electron.enable = true;
    _custom.programs.gtk.enable = true;
    _custom.programs.imv.enable = true;
    _custom.programs.mongodb.enable = true;
    _custom.programs.obs-studio.enable = true;
    _custom.programs.thunar.enable = true;
    _custom.programs.thunar.daemonEnable = true;
    _custom.programs.qt.enable = true;
    _custom.programs.zathura.enable = true;
    _custom.programs.fi.enable = true;
    _custom.programs.fi.openFirewall = true;
    _custom.programs.fi.opensnitchRule = true;

    _custom.programs.others-linux.enable = true;

    # tui
    _custom.programs.figlet.enable = true;
    _custom.programs.fontpreview-kik.enable = true;

    # cli
    _custom.programs.bat.enable = true;
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
    _custom.programs.btop.enableRocm = true;
    _custom.programs.less.enable = true;
    _custom.programs.lynx.enable = true;
    _custom.programs.neovim.enable = true;
    _custom.programs.newsboat.enable = true;
    _custom.programs.presenterm.enable = true;
    _custom.programs.tmux.enable = true;
    _custom.programs.tmux.enableSystemd = true;
    _custom.programs.urlscan.enable = true;
    _custom.programs.yazi.enable = true;
    _custom.programs.youtube.enable = true;
    _custom.programs.zellij.enable = true;
    _custom.programs.ai-agents.enable = true;
    _custom.programs.ai-agents.enableSkills = true;
    _custom.programs.ai-agents.cartridge.enable = true;
    _custom.programs.ai-agents.llmBench.enable = true;
    _custom.programs.ai-agents.sessionTap = {
      enable = true;
      sourceId = "gdesktop";
      sourceName = "gdesktop";
      enableHub = true;
      tokenSecret.sopsFile = ../../secrets-sops/local.yaml;
      tokenSecret.sopsKey = "local-sessiontap-hub-token-gdesktop";
      hubSources.sandbox = {
        sopsFile = ../../secrets-sops/local.yaml;
        sopsKey = "local-sessiontap-hub-token-sandbox";
      };
      remote.interfaces = [ "enp42s0" ];
    };

    _custom.services.tailscale = {
      enable = true;
      loginServer = "https://hs.geanmar.com";
      enableOperator = true;
      startOnBoot = false;
      # keep ssh reachable on the LAN
      sshOnlyTailnet = false;
    };
    _custom.services.remote-desktop.host = {
      enable = true;
      interfaces = [
        "enp42s0"
        "tailscale0"
      ];
      credentials.sopsFile = ../../secrets-sops/local.yaml;
    };
    _custom.services.remote-desktop.client = {
      enable = true;
      hosts.glegion = {
        address = "glegion.local";
        commandName = "glegion-remote";
      };
    };
    _custom.services.android.enable = true;
    _custom.services.android.enableSdk = true;
    _custom.services.podman.enable = true;
    _custom.services.podman.rootless = true;
    _custom.services.podman.dockerCompat = true;
    _custom.services.docker.enable = false;

    _custom.services.media = {
      enable = true;
      dataRoot = "/mnt/storage/media-server";
      services.jellyfin.enable = true;
      services.jellyfin.hardwareAcceleration = "vaapi";
      services.seerr.enable = true;
      services.sonarr.enable = true;
      services.radarr.enable = true;
      services.prowlarr.enable = true;
      services.qbittorrent.enable = true;
      services.bazarr.enable = true;
      services.lazylibrarian.enable = true;
      services.calibreWeb.enable = true;
      services.audiobookshelf.enable = true;
      # API keys: see modules/nixos/services/media/README.md, "Secrets".
      declarative = {
        enable = true;
        admin.username = "wochap";
        admin.passwordSecret = {
          sopsFile = ../../secrets-sops/local.yaml;
          sopsKey = "local-media-admin-password";
        };
        apiKeys =
          lib.genAttrs [ "sonarr" "radarr" "prowlarr" "seerr" ] (name: {
            sopsFile = ../../secrets-sops/local.yaml;
            sopsKey = "local-media-${name}-api-key";
          })
          // {
            # Generated by this host's LazyLibrarian, so the key is per host.
            lazylibrarian = {
              sopsFile = ../../secrets-sops/local.yaml;
              sopsKey = "local-media-gdesktop-lazylibrarian-api-key";
            };
          };
      };
    };
    _custom.services.web-gate.proxies.jellyfin.expose.enable = true;
    _custom.services.web-gate.proxies.seerr.expose.enable = true;
    _custom.services.web-gate.proxies.audiobookshelf.expose.enable = true;
    _custom.services.web-gate.proxies.calibre-web.expose.enable = true;

    # Media UIs other household members use, reachable from the LAN as
    # https://<name>.gdesktop.geanmar.com. They rely on the app's own login: their
    # mobile/TV apps cannot complete the web-gate Basic Auth cookie dance.
    # Admin UIs (sonarr, radarr, ...) stay loopback-only.
    _custom.services.web-gate.domain = "gdesktop.geanmar.com";
    _custom.services.web-gate.acme.credentialSecret.sopsFile = ../../secrets-sops/personal.yaml;
    _custom.services.web-gate.acme.credentialSecret.sopsKey = "personal-cloudflare-dns-api-token";
    # Fixed IP, but DDNS still creates and maintains the record.
    _custom.services.web-gate.ddns.enable = true;
    _custom.services.web-gate.ddns.zone = "geanmar.com";
    # gdesktop.geanmar.com itself, for SSH and remote builds from glegion.
    _custom.services.web-gate.ddns.apex = true;

    # Binary caches in both directions plus remote builds from glegion.
    # Secrets and *.pub files: see modules/nixos/services/nix-cache/README.md.
    _custom.services.nix-cache = {
      server.enable = true;
      server.signingKey.sopsFile = ../../secrets-sops/local.yaml;
      server.signingKey.sopsKey = "local-nix-cache-gdesktop-signing-key";
      server.htpasswd.sopsFile = ../../secrets-sops/local.yaml;
      server.htpasswd.sopsKey = "local-nix-cache-htpasswd";
      client.caches.glegion = {
        url = "https://cache.glegion.geanmar.com";
        publicKey = lib.fileContents ../glegion/nix-cache.pub;
      };
      client.netrc.sopsFile = ../../secrets-sops/local.yaml;
      client.netrc.sopsKey = "local-nix-cache-netrc";
    };

    _custom.services.ai.enable = true;
    _custom.services.ai.enableRocm = true;
    _custom.services.ai.enableHandy = true;
    _custom.services.ai.enableOllama = true;
    _custom.services.ai.enableOllamaFlashAttention = true;
    _custom.services.ai.ocr.enable = true;
    _custom.services.ai.pdfIngest.enable = true;
    _custom.services.ai.enableOpenWebui = true;
    _custom.services.ai.enableSupertonic = true;
    _custom.services.ai.asr.enable = true;
    # Attention memory grows with chunkSeconds^2 * batchSize; 480 s x 4 OOMs
    # on 16 GB (9.3 GiB attention alloc).
    _custom.services.ai.asr.chunkSeconds = 240;
    # gfx1030 has no native bf16 matmul; fp16 runs on the fast path.
    _custom.services.ai.asr.dtype = "float16";
    _custom.services.ai.asr.batchSize = 4;
    _custom.services.ai.enableOmniRoute = true;
    _custom.services.ai.enableFirecrawl = true;
    _custom.services.ai.webscoop.enable = true;
    _custom.services.ai.wosarcher.enable = true;
    _custom.services.ai.wosarcher.jev.enable = true;
    # embeddings-rerank stays available for offline use.
    _custom.services.ai.wosarcher.profile = "embeddings-jev";
    # Reachable from the LAN as https://wosarcher.gdesktop.geanmar.com behind `web-gate`
    # _custom.services.web-gate.proxies.wosarcher.expose.enable = true;
    # _custom.services.web-gate.proxies.wosarcher.expose.gate = true;
    _custom.services.ai.openDesign.enable = true;
    _custom.services.ai.comfyui.enable = true;
    # ComfyUI-GGUF (molbal fork) in ~/ComfyUI/custom_nodes; see comfyui/README.md.
    _custom.services.ai.comfyui.extraPipPackages = [ "gguf>=0.13.0" ];
    # RDNA2 has no bf16 in ComfyUI, so bf16-only models (Qwen-Image-2.1) run in
    # fp32. fp16 avoids that: 25 steps at 1024x1024 went from 17:51 to 11:43.
    _custom.services.ai.comfyui.unetDtype = "fp16";
    _custom.services.ai.comfyui.attention = "split";
    _custom.services.ai.comfyui.rocm.tunableOp = true;
    # 16 GB VRAM: at 40k context the embedding model left only ~6.5 GB free,
    # and the Q8_0 reranker (~7.1 GB: 4.1 GB weights, 2.5 GB compute buffer
    # and 0.6 GB KV cache at contextSize 4096) failed to load. At 30k context
    # the embedding KV cache shrinks by ~1.4 GB, and the Q4_K_M reranker
    # (~5.4 GB: 2.4 GB weights) leaves ~2.6 GB of headroom with both models
    # resident.
    _custom.services.ai.reranker.enable = true;
    _custom.services.ai.reranker.model = "Qwen/Qwen3-Reranker-4B";
    _custom.services.ai.reranker.modelUrl =
      "https://huggingface.co/giladgd/Qwen3-Reranker-4B-GGUF/resolve/main/Qwen3-Reranker-4B.Q4_K_M.gguf";
    _custom.services.ai.reranker.modelSha256 =
      "941f7d1d1524251c026a797b803ac9575545c5d7aa19b26e0e49661d7720af49";
    _custom.services.ai.ollamaEmbeddingModel = "gdesktop-qwen3-embedding:4b";
    _custom.services.ai.enableArticle = true;
    _custom.services.ai.agentsServer.enable = true;
    _custom.services.ai.agentsServer.models = [
      "claude/claude-opus-5-5[1m]"
      "claude/claude-sonnet-5-5"
      "claude/claude-haiku-5-5"
      "claude/claude-fable-5-1"
      "pi/omniroute/desktop-free"
    ];
    _custom.services.ai.briefing.enable = true;

    _custom.services.rsshub.enable = true;
    _custom.services.searxng.enable = true;
    _custom.services.webhook.enable = true;
    _custom.services.wobook.enable = true;
    _custom.services.interception-tools.enable = true;
    _custom.services.ipwebcam.enable = false;
    _custom.services.kdeconnect.enable = true;
    _custom.services.tt.enable = true;

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
    _custom.system.user.password = "$y$j9T$GChzlCM7cdSrWM/gynZTB/$S6k/k6zVDWfl0HBBdJ0lRT1XfGKSQ8lIbtplYgQLgp2";

    _custom.desktop.gtk.bookmarks = [ "file:///mnt/storage Storage" ];

    _custom.desktop.greetd.enable = true;
    _custom.desktop.greetd.enableAutoLogin = true;
    _custom.desktop.greetd.enableLuksIntegration = true;

    _custom.desktop.hyprland.enable = true;
    _custom.desktop.hyprland.isDefault = true;

    _custom.desktop.quickshell.authDialogs.enable = true;
    _custom.desktop.quickshell.authDialogs.polkit = true;
    _custom.desktop.quickshell.authDialogs.pinentry = true;
    _custom.desktop.quickshell.authDialogs.askpass = true;
    _custom.desktop.quickshell.authDialogs.prompter = true;
    _custom.desktop.quickshell.authDialogs.phraseSecret.sopsFile = ../../secrets-sops/local.yaml;
    _custom.desktop.quickshell.authDialogs.phraseSecret.sopsKey = "local-auth-phrase";

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

    _custom.desktop.home-screen.enable = true;
    _custom.desktop.home-screen.finnhub.enable = true;
    _custom.desktop.home-screen.fred.enable = true;
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
