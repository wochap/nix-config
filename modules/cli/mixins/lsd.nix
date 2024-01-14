{ config, lib, inputs, ... }:

let
  cfg = config._custom.cli.lsd;
  userName = config._userName;
  themeSettings = { };
in {
  options._custom.cli.lsd = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        lsd = prev.lsd.overrideAttrs (drv: rec {
          version = "1.0.0";
          src = prev.fetchFromGitHub {
            owner = "lsd-rs";
            repo = "lsd";
            rev = "v${version}";
            hash = "sha256-syT+1LNdigUWkfJ/wkbY/kny2uW6qfpl7KmW1FjZKR8=";
          };
          cargoHash = "sha256-viLr76Bq9OkPMp+BoprQusMDgx59nbevVi4uxjZ+eZg=";
          cargoDeps = drv.cargoDeps.overrideAttrs (_: {
            inherit src;
            outputHash = "sha256-viLr76Bq9OkPMp+BoprQusMDgx59nbevVi4uxjZ+eZg=";
          });
        });
      })
    ];

    home-manager.users.${userName} = {
      xdg.configFile = {
        "lsd/colors.yaml".source = "${inputs.dracula-lsd}/dracula.yaml";
        "lsd/icons.yaml".text = ''
          name:
            mail: 
            Mail: 
        '';
      };

      programs.lsd = {
        # TODO: use package option instead of overlay
        enable = true;
        # adds ls ll la lt ll
        enableAliases = true;
        settings = lib.recursiveUpdate themeSettings {
          color.theme = "custom";
          sorting.dir-grouping = "first";
          symlink-arrow = "->";
          layout = "grid";
          hyperlink = "auto";
          blocks = [ "permission" "user" "group" "size" "date" "git" "name" ];
          date = "+%a %m %b %H:%M %Y";
        };
      };
    };
  };
}
