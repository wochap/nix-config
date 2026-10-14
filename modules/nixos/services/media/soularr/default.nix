{
  config,
  lib,
  pkgs,
  ...
}:

let
  common = import ../common.nix { inherit config lib pkgs; };
  inherit (common) cfg;
  name = "soularr";
  svc = cfg.services.soularr;
  downloadDir = "/data/soulseek/downloads";

  # Soularr expands environment variables in config.ini, so the file holds
  # no secret and the keys come from the env file below. slskd and Lidarr see
  # the downloads at the same path, so both download_dir values match.
  # Unset keys keep Soularr's defaults.
  configFile = (pkgs.formats.ini { }).generate "soularr-config.ini" {
    Lidarr = {
      api_key = "$LIDARR_API_KEY";
      host_url = "http://${common.containerName "lidarr"}:8686";
      download_dir = downloadDir;
      disable_sync = false;
    };
    Slskd = {
      api_key = "$SLSKD_API_KEY";
      host_url = "http://${common.slskdHost}:5030";
      url_base = "/";
      download_dir = downloadDir;
      delete_searches = false;
      stalled_timeout = 3600;
    };
    "Search Settings" = {
      allowed_filetypes = "flac,mp3";
      search_source = "missing";
    };
    Logging.log_to_file = false;
  };
in
{
  config = lib.mkIf (cfg.enable && svc.enable) {
    virtualisation.oci-containers.containers.${common.containerName name} = {
      image = cfg.images.soularr;
      user = common.user;
      networks = [ cfg.network.name ];
      environment = common.umaskEnv // {
        SCRIPT_INTERVAL = toString svc.interval;
        WEBUI_ENABLED = "false";
      };
      environmentFiles = [ config.sops.templates."media-${name}.env".path ];
      # The image reads /data/config.ini; /data is the shared media tree here.
      cmd = [
        "/app/run.sh"
        "--config-dir"
        "/etc/soularr"
        "--var-dir"
        "/config"
      ];
      volumes = [
        "${configFile}:/etc/soularr/config.ini:ro"
        "${common.stateDir name}:/config:rw"
        # Soularr moves finished albums into one folder per album, then asks
        # Lidarr to import that folder.
        (common.dataMount "soulseek/downloads")
      ];
      extraOptions = common.hardening ++ [
        "--read-only"
        "--pids-limit=128"
      ];
    };

    sops.templates."media-${name}.env" = {
      mode = "0400";
      restartUnits = [ "${common.serviceName name}.service" ];
      content = ''
        LIDARR_API_KEY=${config.sops.placeholder.${cfg.declarative.apiKeys.lidarr.sopsKey}}
        SLSKD_API_KEY=${config.sops.placeholder.${cfg.declarative.apiKeys.slskd.sopsKey}}
      '';
    };

    systemd.services.${common.serviceName name} = common.mkSystemdService name {
      extra = {
        wants = [
          "${common.serviceName "lidarr"}.service"
          "${common.serviceName "slskd"}.service"
        ];
        after = [
          "${common.serviceName "lidarr"}.service"
          "${common.serviceName "slskd"}.service"
        ];
      };
    };
    systemd.tmpfiles.rules = [ (common.mkStateRule name) ];
  };
}
