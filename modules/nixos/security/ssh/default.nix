{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.security.ssh;
  inherit (config._custom.globals) configDirectory isSandbox;
in
{
  options._custom.security.ssh.enable = lib.mkEnableOption { };

  # NOTE: ssh agent is managed by gnome-keyring
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        sshfs

        # TUI for ssh
        sshs
      ];

      variables.SSH_ASKPASS_REQUIRE = "prefer";
    };

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    services.fail2ban.enable = !isSandbox;

    _custom.user.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJslBuXKtnHU0vniaw1zedoRB9WhREYLT9kb/oDqo1a gean.marroquin@gmail.com"
    ];

    _custom.hm = {
      home.file = {
        ".ssh/config".source = lib._custom.relativeSymlink configDirectory ./dotfiles/config;
      };
    };
  };
}
