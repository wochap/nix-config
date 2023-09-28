{ config, pkgs, lib, inputs, ... }:

let
  userName = config._userName;
  themeSettings = pkgs._custom.fromYAML "${inputs.dracula-lsd}/config.yaml";
in {
  config = {
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
            outputHash = "sha256-ux6t1Xie0ux0y/2WDgRXfAGGuUSnQ2ErbznHdAtq/F8=";
          });
        });
      })
    ];

    home-manager.users.${userName} = {
      xdg.configFile."lsd/themes/dracula.yaml".source =
        "${inputs.dracula-lsd}/dracula.yaml";
      xdg.configFile."lsd/icons.yaml".text = ''
        name:
          mail: 
          Mail: 
      '';

      programs.lsd = {
        # TODO: use package option instead of overlay
        enable = true;
        # adds ls ll la lt ll
        enableAliases = true;
        settings = lib.recursiveUpdate themeSettings {
          sorting.dir-grouping = "first";
          symlink-arrow = "->";
          layout = "grid";
        };
      };
    };
  };
}
