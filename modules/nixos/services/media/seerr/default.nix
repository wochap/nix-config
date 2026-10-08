{
  config,
  lib,
  pkgs,
  ...
}:

let
  common = import ../common.nix { inherit config lib pkgs; };
  inherit (common) cfg;
  name = "seerr";
  svc = cfg.services.seerr;
  inherit (cfg.services) jellyfin sonarr radarr;
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    virtualisation.oci-containers.containers.${common.containerName name} = {
      image = cfg.images.seerr;
      user = common.user;
      networks = [ cfg.network.name ];
      ports = common.publish svc 5055;
      environment = common.umaskEnv // {
        PORT = "5055";
      };
      environmentFiles = lib.optional common.declarative (common.apiKeyEnvFile name);
      # Seerr talks to Jellyfin, Sonarr and Radarr over the shared network;
      # it needs no media mounts.
      volumes = [ "${common.stateDir name}:/app/config:rw" ];
      extraOptions = common.hardening ++ [ "--pids-limit=512" ];
    };

    systemd.tmpfiles.rules = [ (common.mkStateRule name) ];
    _custom.services.web-proxies.${name} = common.mkProxy name svc;

    sops.templates = lib.mkIf common.declarative (common.mkApiKeyEnv name "API_KEY");

    systemd.services = lib.mkMerge [
      { ${common.serviceName name} = common.mkSystemdService name { }; }
      (lib.mkIf common.declarative (
        common.mkConfigUnit name ./config.sh {
          env = {
            SEERR_URL = common.localUrl svc;
            SEERR_API_KEY_FILE = common.apiKeyFile name;
            SEERR_APP_URL = common.publicUrl name;
            SEERR_JELLYFIN_HOST = common.containerName "jellyfin";
            SEERR_JELLYFIN_URL = common.publicUrl "jellyfin";
            SEERR_JELLYFIN_CHECK_URL = "${common.localUrl jellyfin}/System/Info/Public";
            SEERR_LIBRARIES = "Movies\nShows";
            SEERR_PROFILE = cfg.declarative.seerr.qualityProfile;
            RADARR_URL = lib.optionalString radarr.enable (common.localUrl radarr);
            RADARR_HOST = common.containerName "radarr";
            RADARR_API_KEY_FILE = lib.optionalString radarr.enable (common.apiKeyFile "radarr");
            SONARR_URL = lib.optionalString sonarr.enable (common.localUrl sonarr);
            SONARR_HOST = common.containerName "sonarr";
            SONARR_API_KEY_FILE = lib.optionalString sonarr.enable (common.apiKeyFile "sonarr");
          };
          # Jellyfin's admin and libraries, and the root folders, exist once
          # their bootstrap ran.
          after =
            lib.optional jellyfin.enable "media-jellyfin-config.service"
            ++ lib.optional sonarr.enable "media-sonarr-config.service"
            ++ lib.optional radarr.enable "media-radarr-config.service";
        }
      ))
    ];
  };
}
