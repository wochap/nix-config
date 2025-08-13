{ config, pkgs, lib, inputs, system, ... }:

let cfg = config._custom.programs.others-linux;
in {
  options._custom.programs.others-linux.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = lib.mkIf config._custom.security.gnome-keyring.enable [
      (final: prev: {
        brave = prev.runCommandNoCC "brave" {
          buildInputs = with pkgs; [ makeWrapper ];
        } ''
          makeWrapper ${prev.brave}/bin/brave $out/bin/brave \
          --add-flags "--password-store=gnome-libsecret"
          ln -sf ${prev.brave}/share $out/share
        '';
      })
    ];

    environment.systemPackages = with pkgs; [
      brave
      prevstable-chrome.google-chrome
      prevstable-msedge.microsoft-edge
      inputs.zen-browser.packages."${system}".beta
      galaxy-buds-client
      zoom-us
      # teamviewer

      # NOTE: alt+f12 -> View -> Icon Theme
      # NOTE: alt+f12 -> Appearance
      libreoffice-qt6-fresh
    ];

    # required by libreoffice
    programs.java.enable = true;

    _custom.hm = {
      xdg.desktopEntries =
        lib.mkIf config._custom.security.gnome-keyring.enable {
          brave-browser = {
            name = "Brave Web Browser";
            exec = "brave %U";
          };
        };
    };
  };
}
