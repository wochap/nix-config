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

    # cli
    _custom.programs.core-utils-linux.enable = true;
    _custom.programs.bat.enable = true;
    _custom.programs.core-utils.enable = true;
    _custom.programs.dircolors.enable = true;
    _custom.programs.fzf.enable = true;
    _custom.programs.git.enable = true;
    _custom.programs.lsd.enable = true;
    _custom.programs.zoxide.enable = true;
    _custom.programs.zsh.enable = true;
    _custom.programs.zsh.isDefault = false;

    # tui
    _custom.programs.btop.enable = true;
    _custom.programs.less.enable = true;
    _custom.programs.neovim.enable = true;
    _custom.programs.tmux.enable = true;

    _custom.archetypes.server.enable = true;

    # never put the personal age key on a public VPS
    _custom.security.sops.enable = lib.mkForce false;

    # desktop networking brings NetworkManager, dev port ranges and a resolved
    # stub that clashes with AdGuard on :53
    _custom.desktop.networking.enable = lib.mkForce false;
    _custom.desktop.power-management.enable = lib.mkForce false;
    networking.useDHCP = true;
    networking.firewall.enable = true;
    networking.nameservers = [ "9.9.9.9" ];
    services.resolved.enable = false;

    # TODO: replace with real domain
    _custom.services.headscale = {
      enable = true;
      domain = "hs.example.com";
      baseDomain = "tail.example.com";
    };
    _custom.services.tailscale = {
      enable = true;
      sshOnlyTailnet = false;
    };
    _custom.services.adguardhome.enable = true;

    _custom.system.user.password = "$6$rvioLchC4DiAN732$Me4ZmdCxRy3bacz/eGfyruh5sVVY2wK5dorX1ALUs2usXMKCIOQJYoGZ/qKSlzqbTAu3QHh6OpgMYgQgK92vn.";

    time.timeZone = "America/Panama";

    system.stateVersion = "26.05";
    home-manager.users.${userName}.home.stateVersion = "26.05";
  };
}
