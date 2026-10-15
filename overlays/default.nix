{
  lib,
  config,
  inputs,
  ...
}:

let
  # NOTE: never add the custom channels overlay here, channels are built
  # from this list and would recurse into themselves
  sharedOverlays = [ inputs.self.overlays.default ] ++ config._custom.overlays;

  mkChannel =
    input: prev:
    import input {
      inherit (prev.stdenv.hostPlatform) system;
      inherit (config.nixpkgs) config;
      overlays = sharedOverlays;
    };
in
{
  options._custom.overlays = lib.mkOption {
    type = lib.types.listOf (
      lib.mkOptionType {
        name = "nixpkgs-overlay";
        description = "nixpkgs overlay";
        check = lib.isFunction;
        merge = lib.mergeOneOption;
      }
    );
    default = [ ];
    description = ''
      Overlays applied to the system pkgs and to every custom channel
      (pkgs.nixpkgs-unstable, pkgs.prevstable-*). Modules should add their
      overlays here instead of `nixpkgs.overlays`, so the channels get them too.
    '';
  };

  options._custom.permittedInsecurePackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      Merged into `nixpkgs.config.permittedInsecurePackages`. Modules should
      add entries here instead of setting `nixpkgs.config` directly: its
      definitions are combined with `recursiveUpdate`, so lists from different
      modules override each other instead of concatenating.
    '';
  };

  config = {
    nixpkgs.config.permittedInsecurePackages = lib.unique config._custom.permittedInsecurePackages;

    nixpkgs.overlays = sharedOverlays ++ [
      # Custom channels
      (final: prev: {
        nixpkgs-master = mkChannel inputs.nixpkgs-master prev;
        nixpkgs-unstable = mkChannel inputs.nixpkgs-unstable prev;
        prevstable-mesa = mkChannel inputs.prevstable-mesa prev;
        prevstable-chrome = mkChannel inputs.prevstable-chrome prev;
        prevstable-neovim = mkChannel inputs.prevstable-neovim prev;
        prevstable-python = mkChannel inputs.prevstable-python prev;
        prevstable-gaming = mkChannel inputs.prevstable-gaming prev;
        prevstable-intune = mkChannel inputs.prevstable-intune prev;
        prevstable-msedge = mkChannel inputs.prevstable-msedge prev;
      })
    ];
  };
}
