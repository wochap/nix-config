{
  config,
  lib,
  ...
}:

let
  cfg = config._custom.sandbox;
  inherit (cfg) userName;
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
in
{
  options._custom.sandbox = {
    userName = lib.mkOption {
      type = lib.types.str;
      default = "sandbox";
    };
  };

  config = {
    _custom.globals.userName = userName;
    _custom.globals.homeDirectory = "/home/${userName}";
    _custom.globals.configDirectory = configDirectory;
    _custom.globals.preferDark = true;
    _custom.globals.isSandbox = true;

    _custom.archetypes.sandbox.enable = true;

    # cli
    _custom.programs.core-utils-extra-linux.enable = true;
    _custom.programs.core-utils-linux.enable = true;
    _custom.programs.nix-direnv.enable = true;

    # gui
    # _custom.programs.dolphin.enable = true;
    # _custom.programs.electron.enable = true;
    # _custom.programs.gtk.enable = true;
    # _custom.programs.imv.enable = true;
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
    # _custom.programs.cht.enable = true;
    _custom.programs.core-utils-extra.enable = true;
    _custom.programs.core-utils.enable = true;
    _custom.programs.dircolors.enable = true;
    _custom.programs.fzf.enable = true;
    _custom.programs.git.enable = true;
    _custom.programs.git.enableUser = false;
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
    _custom.programs.lang-c.enable = true;
    _custom.programs.lang-go.enable = true;
    # _custom.programs.lang-lua.enable = true;
    # _custom.programs.lang-nix.enable = true;
    _custom.programs.lang-python.enable = true;
    # _custom.programs.lang-qt.enable = true;
    # _custom.programs.lang-ruby.enable = true;
    _custom.programs.lang-rust.enable = true;
    _custom.programs.lang-web.enable = true;
    _custom.programs.tools.enable = true;

    # gui
    # _custom.programs.discord.enable = true;
    _custom.programs.firefox.enable = true;
    _custom.programs.foot.enable = true;
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
    # _custom.programs.nnn.enable = true;
    # _custom.programs.presenterm.enable = true;
    # _custom.programs.taskwarrior.enable = true;
    _custom.programs.tmux.enable = true;
    # _custom.programs.tmux.systemdEnable = true;
    # _custom.programs.urlscan.enable = true;
    # _custom.programs.youtube.enable = true;
    _custom.programs.claude-code.enable = true;

    # _custom.services.android.enable = true;
    # _custom.services.android.sdk.enable = false;
    # _custom.services.docker.enable = true;
    # _custom.services.docker.enableNvidia = true;
    # _custom.services.flatpak.enable = false;
    # _custom.services.interception-tools.enable = true;
    # _custom.services.ipwebcam.enable = true;
    # _custom.services.kdeconnect.enable = true;
    # _custom.services.ai.enable = true;
    # _custom.services.ai.enableWhisper = true;
    # _custom.services.ai.enablePix2tex = true;
    # _custom.services.ai.enableOllama = true;
    # _custom.services.ai.enableNvidia = true;
    # _custom.services.ai.enableOllamaWebuiLite = false;
    # _custom.services.ai.enableNextjsOllamaLlmUi = false;
    # _custom.services.ai.enableOpenWebui = true;
    # _custom.services.ms-intune.enable = true;

    # _custom.services.syncthing.enable = true;
    # _custom.services.virt.enable = false;
    # _custom.services.waydroid.enable = false;

    # _custom.gaming.emulators.enable = false;
    # _custom.gaming.steam.enable = true;
    # _custom.gaming.utils.enable = true;

    # fix blurry cursor on GTK 3 apps
    # update catppuccin cursor NOMINAL_SIZE
    # TODO: remove after updating gtk to 4.18
    # source: https://blogs.kde.org/2024/10/09/cursor-size-problems-in-wayland-explained/#my-fix-or-shall-we-say-workaround
    # source: https://gitlab.gnome.org/GNOME/gtk/-/merge_requests/7722
    # source: https://bbs.archlinux.org/viewtopic.php?id=299624
    _custom.desktop.cursor.name = "catppuccin-mocha-dark-cursors";
    _custom.desktop.cursor.size = 24;

    time.timeZone = "America/Panama";

    system.stateVersion = "23.11";

    home-manager.users.${userName}.home.stateVersion = "23.11";
  };
}
