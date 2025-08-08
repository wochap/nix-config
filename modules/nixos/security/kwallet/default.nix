{ config, pkgs, lib, ... }:

let cfg = config._custom.security.kwallet;
in {
  options._custom.security.kwallet.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      kwallet # provides helper service
      kwalletmanager # A GUI to manage your KWallet
      kwallet-pam # provides helper service
    ];

    xdg.portal.extraPortals = with pkgs; [ kdePackages.kwallet ];

    security.pam.services = {
      login.kwallet = {
        enable = true;
        package = pkgs.kdePackages.kwallet-pam;
      };

      greetd.kwallet = lib.mkIf config._custom.desktop.greetd.enable {
        enable = true;
        package = pkgs.kdePackages.kwallet-pam;
      };
    };

    programs.ssh.askPassword =
      "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";

    programs.gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-qt;
      # Allows it to function as an ssh-agent
      enableSshSupport = true;
    };

    xdg.portal.config = {
      common."org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
      Hyprland."org.freedesktop.impl.portal.Secret" =
        lib.mkIf config._custom.desktop.hyprland.enable [ "kwallet" ];
    };

    _custom.hm = {
      # SSH integration
      # home.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";

      # systemd.user.services.gnome-keyring = {
      #   Unit = {
      #     Description = "GNOME Keyring";
      #     PartOf = [ "graphical-session-pre.target" ];
      #   };
      #   Service = {
      #     # Use wrapped gnome-keyring-daemon with cap_ipc_lock=ep
      #     ExecStart =
      #       "/run/wrappers/bin/gnome-keyring-daemon --start --foreground --components=secrets,ssh,pkcs11";
      #     Restart = "on-abort";
      #   };
      #   Install.WantedBy = [ "graphical-session-pre.target" ];
      # };
    };
  };
}
