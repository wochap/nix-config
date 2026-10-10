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
  ];

  config = {
    _custom.globals.userName = userName;
    _custom.globals.homeDirectory = "/home/${userName}";
    _custom.globals.configDirectory = configDirectory;
    _custom.globals.preferDark = true;

    _custom.archetypes.server.enable = true;

    # cli
    # _custom.programs.core-utils-extra-linux.enable = true;
    _custom.programs.core-utils-linux.enable = true;
    _custom.programs.nix-direnv.enable = true;

    # gui
    # none

    # tui
    # none

    # cli
    _custom.programs.bat.enable = true;
    # _custom.programs.core-utils-extra.enable = true;
    _custom.programs.core-utils.enable = true;
    _custom.programs.dircolors.enable = true;
    _custom.programs.fzf.enable = true;
    _custom.programs.git.enable = true;
    _custom.programs.git.settings = {
      user = {
        email = "gvps@localhost";
        name = "gvps";
      };
    };
    _custom.programs.lazygit.enable = true;
    _custom.programs.lsd.enable = true;
    # _custom.programs.ptsh.enable = true;
    # _custom.programs.texlive.enable = true;
    _custom.programs.zk.enable = true;
    _custom.programs.zoxide.enable = true;
    _custom.programs.zsh.enable = true;
    _custom.programs.zsh.isDefault = false;

    # dev
    # none

    # gui
    # none

    # tui
    # _custom.programs.amfora.enable = true;
    _custom.programs.btop.enable = true;
    _custom.programs.less.enable = true;
    # _custom.programs.lynx.enable = true;
    _custom.programs.neovim.enable = true;
    # _custom.programs.newsboat.enable = true;
    # _custom.programs.presenterm.enable = true;
    # _custom.programs.taskwarrior.enable = true;
    _custom.programs.tmux.enable = true;
    # _custom.programs.tmux.enableSystemd = true;
    # _custom.programs.urlscan.enable = true;
    _custom.programs.yazi.enable = true;
    # _custom.programs.youtube.enable = true;
    # _custom.programs.zellij.enable = true;
    # _custom.programs.ai-agents.enable = true;

    _custom.system.user.password = "$y$j9T$GChzlCM7cdSrWM/gynZTB/$S6k/k6zVDWfl0HBBdJ0lRT1XfGKSQ8lIbtplYgQLgp2";

    # public network: plain DHCP, no NetworkManager, dev ports or mDNS
    _custom.desktop.networking.enableIPv6 = true;
    _custom.desktop.networking.nameservers = [ "9.9.9.9" ];

    _custom.desktop.power-management.enable = false;

    # hs: Cloudflare A record, DNS only. tail: MagicDNS suffix, no public record
    _custom.services.headscale = {
      enable = true;
      domain = "hs.geanmar.com";
      baseDomain = "tail.geanmar.com";
    };
    _custom.services.tailscale = {
      enable = true;
      sshOnlyTailnet = false;
      # once gvps joined the tailnet and ssh over it works (KVM console is the fallback)
      # sshOnlyTailnet = true;
    };
    _custom.services.adguardhome.enable = true;

    time.timeZone = "America/Toronto";

    system.stateVersion = "26.05";
    home-manager.users.${userName}.home.stateVersion = "26.05";
  };
}
