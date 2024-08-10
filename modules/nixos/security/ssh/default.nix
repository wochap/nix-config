{ config, pkgs, lib, ... }:

let
  cfg = config._custom.security.ssh;
  inherit (config._custom.globals) configDirectory;
in {
  options._custom.security.ssh.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sshfs

      # TUI for ssh
      sshs
    ];

    services.openssh.enable = true;
    services.openssh.settings.PasswordAuthentication = false;
    services.openssh.settings.KbdInteractiveAuthentication = false;

    _custom.user.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJslBuXKtnHU0vniaw1zedoRB9WhREYLT9kb/oDqo1a gean.marroquin@gmail.com"
    ];

    _custom.hm = {
      # NOTE: ssh agent managed by gnome-keyring
      home.file = {
        ".ssh/config".source =
          lib._custom.relativeSymlink configDirectory ./dotfiles/config;
        ".ssh/config.d/boc".source = ../../../../secrets/dotfiles/ssh/boc;
      };
    };
  };
}
