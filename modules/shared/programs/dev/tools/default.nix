{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.programs.tools;
  jira-ticket = pkgs.writeScriptBin "jira-ticket" (builtins.readFile ./scripts/jira-ticket.sh);
  git-sync-all = pkgs.writeScriptBin "git-sync-all" (builtins.readFile ./scripts/git-sync-all.sh);
in
{
  options._custom.programs.tools.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        ansible # automation scripts
        awscli
        mkcert # create certificates (HTTPS)
        ngrok # expose web server
        stripe-cli
        watchman # required by react native
        jira-ticket
        git-sync-all
      ];
    };
  };
}
