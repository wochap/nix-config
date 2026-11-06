{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.programs.geancam;
  yamlFormat = pkgs.formats.yaml { };

  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};
  inherit (pkgs._custom) wochap-ssc;
  host = "http://${wochap-ssc.meta.address}";
  omniRouteProxy = config._custom.services.web-gate.proxies.omniroute;
  omniRoutePublicPort = omniRouteProxy.publicPort or 20128;
in
{
  options._custom.programs.geancam = {
    enable = lib.mkEnableOption { };
    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.geancam.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Configuration for geancam merged into ~/.config/geancam/config.yaml.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    _custom.programs.geancam.settings = {
      library = lib.mkDefault "/mnt/storage/geancam";
      inbox = lib.mkDefault "/mnt/storage/geancam-inbox";
      timezone = lib.mkDefault "America/Panama";

      ingest = {
        channels = lib.mkDefault [
          "F"
        ];
      };

      preview = {
        height = lib.mkDefault 540;
      };

      render = {
        profile = lib.mkDefault "auto";
        profiles = {
          gdesktop = lib.mkDefault {
            video_codec = "hevc_vaapi";
            crf = 18;
            bitrate = "50M";
          };
          glegion = lib.mkDefault {
            video_codec = "h264_nvenc";
            bitrate = "70M";
          };
        };
      };

      translation = {
        provider = lib.mkDefault "omniroute";
        base_url = lib.mkDefault "${host}:${toString omniRoutePublicPort}/v1";
        model = lib.mkDefault "geancam";
        api_key = lib.mkDefault { file = config.sops.secrets.local-omniroute-secret-key.path; };
        glossary = lib.mkDefault [
          "Tacna"
          "Tarata"
          "picante"
          "peaje"
        ];
      };

      places = {
        extract_url = lib.mkDefault "https://download.geofabrik.de/south-america/peru-latest.osm.pbf";
        auto_milestones = lib.mkDefault {
          kinds = [
            "city"
            "town"
          ];
          min_gap_s = 180;
        };
      };

      music = {
        library = lib.mkDefault "~/Music/geancam";
        target_lufs = lib.mkDefault (-14);
      };

      blur = {
        enabled = lib.mkDefault true;
        faces = lib.mkDefault true;
        plates = lib.mkDefault true;
      };

      thresholds = {
        drive_gap_s = lib.mkDefault 120;
        same_trip_overnight_radius_m = lib.mkDefault 500;
        stationary_min_s = lib.mkDefault 20;
        stationary_cut_full_s = lib.mkDefault 120;
      };
    };

    _custom.hm = {
      xdg.configFile."geancam/config.yaml".source =
        yamlFormat.generate "geancam-config.yaml" cfg.settings;

      home.packages = [ cfg.package ];

      home.symlinks = {
        "${hmConfig.home.homeDirectory}/Music/geancam" =
          "${hmConfig.home.homeDirectory}/Sync/music/geancam";
      };
    };
  };
}
