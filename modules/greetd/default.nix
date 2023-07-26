{ config, pkgs, lib, inputs, ... }:

let cfg = config._custom.greetd;
in {
  options._custom.greetd = {
    enable = lib.mkEnableOption { };
    cmd = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = ''
            ${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --asterisks --cmd "${cfg.cmd}"'';
          user = "greeter";
        };
      };
    };

    # HACK: stop printing status messages in tuigreet
    # https://github.com/apognu/tuigreet/issues/68#issuecomment-1192683029
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      ExecStartPre = "kill -SIGRTMIN+21 1";
      ExecStopPost = "kill -SIGRTMIN+20 1";
    };
  };
}
