{ config, inputs, lib, pkgs, ... }:

let
  cfg = config._custom.programs.qutebrowser;
  inherit (config._custom.globals) themeColors;
in {
  options._custom.programs.qutebrowser.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      xdg.configFile."qutebrowser/catppuccin".source =
        inputs.catppuccin-qutebrowser;

      programs.qutebrowser = {
        enable = true;
        package = pkgs.qutebrowser;
        enableDefaultBindings = true;
        quickmarks = {
          home-manager =
            "https://nix-community.github.io/home-manager/options.html";
          nixos-packages = "https://search.nixos.org/packages";
        };
        searchEngines = { g = "https://www.google.com/search?hl=en&q={}"; };
        extraConfig = ''
          import catppuccin

          # set the flavour you'd like to use
          # last argument (optional, default is False): enable the plain look for the menu rows
          catppuccin.setup(c, '${themeColors.flavour}', True)

          c.fonts.default_family = "Iosevka NF"
          c.fonts.default_size = "10pt"
        '';
      };
    };
  };
}
