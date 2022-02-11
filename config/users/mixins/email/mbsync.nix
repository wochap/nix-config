{ config, pkgs, lib, ... }:

let
  userName = config._userName;
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
  config = {
    home-manager.users.${userName} = {

      programs.mbsync.enable = true;

      services.mbsync = {
        enable = true;
        preExec = "${checkNetworkOrAlreadyRunningScript}";
        frequency = "*:0/10";
      };
    };
  };
}
