{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.desktop.a11y;

  # Chromium only populates its AT-SPI tree with this flag,
  # ACCESSIBILITY_ENABLED=1 alone exposes an empty frame
  withRendererA11y =
    prev: pkg: bin:
    prev.symlinkJoin {
      inherit (pkg) name meta;
      paths = [ pkg ];
      nativeBuildInputs = [ prev.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/${bin} --add-flags --force-renderer-accessibility

        # desktop entries that exec the unwrapped store path skip the flag
        for f in $out/share/applications/*.desktop; do
          [ -e "$f" ] || continue
          if grep -q "${pkg}/bin/" "$f"; then
            src=$(readlink -f "$f")
            rm "$f"
            sed "s|${pkg}/bin/|$out/bin/|g" "$src" > "$f"
          fi
        done
      '';
    };
in
{
  options._custom.desktop.a11y.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.sessionVariables = {
      # Electron/Chromium, registers on the bus, contents need
      # --force-renderer-accessibility (see overlay)
      ACCESSIBILITY_ENABLED = "1";

      # GTK
      # GTK_MODULES = "gail:atk-bridge";
      GNOME_ACCESSIBILITY = "1";

      # Qt
      QT_ACCESSIBILITY = "1";
      QT_LINUX_ACCESSIBILITY_ALWAYS_ON = "1";

      # LibreOffice: use the gtk VCL plugin, exposes AT-SPI tree
      OOO_FORCE_DESKTOP = "gnome";
    };

    services.gnome.at-spi2-core.enable = true;

    nixpkgs.overlays = [
      (final: prev: {
        bitwarden-desktop = withRendererA11y prev prev.bitwarden-desktop "bitwarden";
        element-desktop = withRendererA11y prev prev.element-desktop "element-desktop";
        legcord = withRendererA11y prev prev.legcord "legcord";
        obsidian = withRendererA11y prev prev.obsidian "obsidian";
        slack = withRendererA11y prev prev.slack "slack";
      })
    ];

    _custom.hm = {
      # gsettings toolkit-accessibility, required by GTK3 apps
      dconf.settings."org/gnome/desktop/interface".toolkit-accessibility = true;

      # Enable org.a11y.Status.IsEnabled on the a11y bus, otherwise GTK3 apps
      # may not register with AT-SPI
      systemd.user.services.a11y-enable = lib._custom.mkGraphicalService {
        # busctl call D-Bus activates org.a11y.Bus, no explicit dependency needed
        Unit.Description = "Enable AT-SPI accessibility bus";
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.systemd}/bin/busctl --user set-property org.a11y.Bus /org/a11y/bus org.a11y.Status IsEnabled b true";
        };
      };
    };
  };
}
