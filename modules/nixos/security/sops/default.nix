{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.security.sops;
  inherit (config._custom.globals) userName isSandbox;
  hmConfig = config.home-manager.users.${userName};
  sharedSopsFile = ../../../../secrets-sops/shared.yaml;
  personalSopsFile = ../../../../secrets-sops/personal.yaml;
  seSopsFile = ../../../../secrets-sops/se.yaml;

  mailEnabled = config._custom.desktop.mail.enable;
  vdirsyncerEnabled =
    config._custom.desktop.calendar.enable || config._custom.desktop.contacts.enable;
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options._custom.security.sops.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    sops = {
      age = {
        keyFile = "${hmConfig.xdg.configHome}/sops/age/keys.txt";
        generateKey = true;
      };

      # secrets land in /run/secrets/<name>, owned by the user, mode 0400
      secrets = {
        "openrouter-api-key" = {
          sopsFile = sharedSopsFile;
          owner = userName;
        };
        "qwen-api-key" = {
          sopsFile = sharedSopsFile;
          owner = userName;
        };
      }
      // lib.optionalAttrs (!isSandbox) {
        # personal
        "deepseek-api-key" = {
          owner = userName;
          sopsFile = personalSopsFile;
        };
        "google-ai-studio-api-key" = {
          owner = userName;
          sopsFile = personalSopsFile;
        };
        "groq-api-key" = {
          owner = userName;
          sopsFile = personalSopsFile;
        };
        "together-api-key" = {
          owner = userName;
          sopsFile = personalSopsFile;
        };
        "unsplash-access-key" = {
          owner = userName;
          sopsFile = personalSopsFile;
        };
        "unsplash-secret-key" = {
          owner = userName;
          sopsFile = personalSopsFile;
        };
        "personal-mail-password" = lib.mkIf mailEnabled {
          owner = userName;
          sopsFile = personalSopsFile;
        };
        "vdirsyncer-client-id" = lib.mkIf vdirsyncerEnabled {
          owner = userName;
          sopsFile = personalSopsFile;
        };
        "vdirsyncer-client-secret" = lib.mkIf vdirsyncerEnabled {
          owner = userName;
          sopsFile = personalSopsFile;
        };

        # se
        "se-gh-token" = {
          owner = userName;
          sopsFile = seSopsFile;
        };
        "se-jira-api-token" = {
          owner = userName;
          sopsFile = seSopsFile;
        };
        "se-mail-password" = lib.mkIf mailEnabled {
          owner = userName;
          sopsFile = seSopsFile;
        };
        "se-slack-d-cookie" = {
          owner = userName;
          sopsFile = seSopsFile;
        };
        "se-slack-token" = {
          owner = userName;
          sopsFile = seSopsFile;
        };
      };
    };
  };
}
