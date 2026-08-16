{
  config,
  lib,
  pkgs,
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

in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options._custom.security.sops.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ sops ];

    sops = {
      age = {
        keyFile = "${hmConfig.xdg.configHome}/sops/age/keys.txt";
        generateKey = true;
      };

      # secrets land in /run/secrets/<name>, owned by the user, mode 0400
      secrets = {
        "personal-openrouter-api-key" = {
          sopsFile = sharedSopsFile;
          owner = userName;
        };
        "personal-a-qwen-token-plan-api-key" = {
          sopsFile = sharedSopsFile;
          owner = userName;
        };
        "personal-b-qwen-token-plan-api-key" = {
          sopsFile = sharedSopsFile;
          owner = userName;
        };
      }
      // lib.optionalAttrs (!isSandbox) {
        # personal
        "personal-deepseek-api-key" = {
          owner = userName;
          sopsFile = personalSopsFile;
        };
        "personal-google-ai-studio-api-key" = {
          owner = userName;
          sopsFile = personalSopsFile;
        };
        "personal-groq-api-key" = {
          owner = userName;
          sopsFile = personalSopsFile;
        };
        "personal-together-api-key" = {
          owner = userName;
          sopsFile = personalSopsFile;
        };
        "personal-unsplash-access-key" = {
          owner = userName;
          sopsFile = personalSopsFile;
        };
        "personal-unsplash-secret-key" = {
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
