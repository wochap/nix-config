{ config, inputs, lib, ... }:

let cfg = config._custom.programs.qutebrowser;
in {
  options._custom.programs.qutebrowser.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    _custom.hm = {
      xdg.configFile."qutebrowser/catppuccin".source =
        inputs.catppuccin-qutebrowser;

      programs.qutebrowser = {
        enable = true;
        enableDefaultBindings = true;
        quickmarks = {
          home-manager =
            "https://nix-community.github.io/home-manager/options.html";
          nixos-packages = "https://search.nixos.org/packages";
        };
        searchEngines = { g = "https://www.google.com/search?hl=en&q={}"; };
        extraConfig = ''
          import catppuccin

          # set the flavor you'd like to use
          # valid options are 'mocha', 'macchiato', 'frappe', and 'latte'
          # last argument (optional, default is False): enable the plain look for the menu rows
          catppuccin.setup(c, 'mocha', True)

          c.fonts.default_family = "Iosevka Nerd Font"
          c.fonts.default_size = "10pt"
        '';
      };
    };
  };
}
