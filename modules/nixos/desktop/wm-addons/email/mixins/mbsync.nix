{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.email;
  mbsyncNames = lib.attrNames (lib.filterAttrs (_: sync: sync == "mbsync") cfg.accounts);
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
in
{
  # only enable mbsync when at least one account still uses it (gmail
  # accounts are synced by lieer instead, see mixins/lieer.nix)
  config = lib.mkIf (cfg.enable && mbsyncNames != [ ]) {
    _custom.hm = {
      programs.mbsync.enable = true;

      services.mbsync = {
        enable = true;
        preExec = "${checkNetworkOrAlreadyRunningScript}";
        # index the freshly synced mail, same role the lieer units'
        # ExecStartPost plays for gmail accounts
        postExec = "${pkgs.notmuch}/bin/notmuch new";
        frequency = "*:0/10";
      };

      systemd.user.services.mbsync.Unit.OnFailure = "mbsync-on-failure.service";

      systemd.user.services.mbsync-on-failure = {
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.libnotify}/bin/notify-send --app-name mbsync --app-icon apport --icon apport --hint=int:transient:1 'Service failed'";
        };
      };
    };
  };
}
