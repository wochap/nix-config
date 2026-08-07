{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.security.ssh;
  inherit (config._custom.globals) configDirectory isSandbox userName;
  hmConfig = config.home-manager.users.${userName};
in
{
  options._custom.security.ssh = {
    enable = lib.mkEnableOption { };
    enableLuksIntegration = lib.mkEnableOption { };
    luksUnlockedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of SSH key filenames to symlink to ~/.ssh/login-keys.d/ for pam_ssh unlock.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = with pkgs; [
          sshfs

          # TUI for ssh
          sshs
        ];

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
      }

      (lib.mkIf cfg.enableLuksIntegration {
        _custom.hm = {
          home.symlinks = builtins.listToAttrs (
            map (key: {
              name = "${hmConfig.home.homeDirectory}/.ssh/login-keys.d/${key}";
              value = "${hmConfig.home.homeDirectory}/.ssh/${key}";
            }) cfg.luksUnlockedKeys
          );
        };
        environment.variables = {
          SSH_ASKPASS = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
          SSH_ASKPASS_REQUIRE = "prefer";
        };

        security.pam.services = {
          login.rules.auth.ssh = {
            order = 20;
            control = "optional";
            modulePath = "${pkgs._custom.pam-ssh}/lib/security/pam_ssh.so";
            args = [ "use_first_pass" ];
          };
          login.rules.session.ssh = {
            order = 20;
            control = "optional";
            modulePath = "${pkgs._custom.pam-ssh}/lib/security/pam_ssh.so";
          };
          greetd.rules.auth.ssh = {
            order = 20;
            control = "optional";
            modulePath = "${pkgs._custom.pam-ssh}/lib/security/pam_ssh.so";
            args = [ "use_first_pass" ];
          };
          greetd.rules.session.ssh = {
            order = 20;
            control = "optional";
            modulePath = "${pkgs._custom.pam-ssh}/lib/security/pam_ssh.so";
          };
        };
      })
    ]
  );
}
