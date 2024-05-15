{ config, pkgs, lib, ... }:

let
  cfg = config._custom.desktop.email;
  checkNetworkOrAlreadyRunningScript = pkgs.writeShellScript "cknetpgrep" ''
    # Check that the network is up.
    ${pkgs.iputils}/bin/ping -c 1 8.8.8.8
    if [[ "$?" != "0" ]]; then
      echo "Couldn't contact the network. Exiting..."
      exit 1
    fi

    # Chcek to see if we are already syncing.
    if ${pkgs.procps}/bin/pgrep mbsync &>/dev/null; then
      echo "Process $pid already running. Exiting..." >&2
      exit 1
    fi
  '';
in {
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      programs.mbsync.enable = true;

      services.mbsync = {
        enable = true;
        preExec = "${checkNetworkOrAlreadyRunningScript}";
        frequency = "*:0/10";
      };

      systemd.user.services.mbsync.Unit.OnFailure = "mbsync-on-failure.service";

      systemd.user.services.mbsync-on-failure = {
        Service = {
          Type = "oneshot";
          ExecStart =
            "${pkgs.libnotify}/bin/notify-send --app-name mbsync --icon apport 'Service failed'";
        };
      };
    };
  };
}
