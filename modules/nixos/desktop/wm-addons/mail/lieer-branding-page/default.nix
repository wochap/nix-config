{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.desktop.mail.lieerBrandingPage;
  useCloudflareAcme = cfg.cloudflareTokenSecret.sopsFile != null;

  templateVars = {
    appName = cfg.appName;
    domain = cfg.domain;
    contactEmail = cfg.contactEmail;
  };

  indexHtml = pkgs.replaceVars ./index.html templateVars;
  privacyHtml = pkgs.replaceVars ./privacy.html templateVars;

  siteRoot = pkgs.runCommand "lieer-branding-page" { } ''
    mkdir -p "$out"
    cp ${indexHtml} "$out/index.html"
    cp ${privacyHtml} "$out/privacy.html"
  '';
in
{
  options._custom.desktop.mail.lieerBrandingPage = {
    enable = lib.mkEnableOption "Static homepage and privacy policy for Lieer Google OAuth branding";

    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      example = "lieer.example.com";
      description = "Public subdomain serving the Lieer OAuth branding pages.";
    };

    appName = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "Lieer";
      description = "Application name displayed on the homepage and privacy policy.";
    };

    contactEmail = lib.mkOption {
      type = lib.types.nonEmptyStr;
      example = "you@gmail.com";
      description = "Contact email displayed on the homepage and privacy policy.";
    };

    cloudflareTokenSecret = {
      sopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          SOPS file with a Cloudflare API token (Zone DNS Edit, Zone Read) for
          DNS-01 ACME certificates. Recommended when proxying the subdomain
          through Cloudflare (orange cloud) for DDoS protection. When null,
          Caddy obtains a certificate automatically via HTTP-01.
        '';
      };
      sopsKey = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "server-cloudflare-dns-api-token";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.caddy = {
          enable = true;
          virtualHosts.${cfg.domain} = {
            extraConfig = ''
              encode zstd gzip

              header {
                X-Content-Type-Options "nosniff"
                X-Frame-Options "DENY"
                Referrer-Policy "no-referrer"
                Content-Security-Policy "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'"
                Cache-Control "public, max-age=86400"
              }

              @disallowed not method GET HEAD
              respond @disallowed 405

              handle / {
                root * ${siteRoot}
                rewrite * /index.html
                file_server
              }

              handle /privacy {
                root * ${siteRoot}
                rewrite * /privacy.html
                file_server
              }

              handle {
                respond 404
              }
            '';
          }
          // lib.optionalAttrs useCloudflareAcme {
            useACMEHost = cfg.domain;
          };
        };

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];
      }

      (lib.mkIf useCloudflareAcme {
        sops.secrets.${cfg.cloudflareTokenSecret.sopsKey}.sopsFile = cfg.cloudflareTokenSecret.sopsFile;

        security.acme = {
          acceptTerms = true;
          certs.${cfg.domain} = {
            dnsProvider = "cloudflare";
            # the local resolver may answer from cache
            dnsResolver = "1.1.1.1:53";
            group = config.services.caddy.group;
            reloadServices = [ "caddy.service" ];
            credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
              config.sops.secrets.${cfg.cloudflareTokenSecret.sopsKey}.path;
          };
        };
      })
    ]
  );
}
