{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.programs.others-linux;
  brave-final = pkgs.brave;
in
{
  options._custom.programs.others-linux.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = lib.mkIf config._custom.security.gnome-keyring.enable [
      (final: prev: {
        brave =
          prev.runCommand "brave"
            {
              buildInputs = with pkgs; [ makeWrapper ];
            }
            ''
              makeWrapper ${prev.brave}/bin/brave $out/bin/brave \
              --add-flags "--password-store=gnome-libsecret"
              ln -sf ${prev.brave}/share $out/share
            '';
      })
    ];

    _custom.security.apparmor.policies.discord = {
      enable = lib.mkDefault true;
      pkg = brave-final;
    };

    environment.systemPackages = with pkgs; [
      brave-final
      prevstable-chrome.google-chrome
      prevstable-msedge.microsoft-edge
      inputs.zen-browser.packages."${stdenv.hostPlatform.system}".beta
      inputs.kb-hud.packages."${stdenv.hostPlatform.system}".default
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
      xdg.desktopEntries = lib.mkIf config._custom.security.gnome-keyring.enable {
        brave-browser = {
          name = "Brave Web Browser";
          exec = "brave %U";
        };
      };
    };
  };
}
