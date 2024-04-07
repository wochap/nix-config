# source: https://github.com/ayamir/nvimdots/blob/main/nixos/neovim/default.nix
{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config._custom.programs.neovim;
  inherit (config._custom.globals) userName;
  hmConfig = config.home-manager.users.${userName};

  # Inspired from https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/programs/nix-ld.nix
  build-dependent-pkgs = with pkgs;
    [
      acl
      attr
      bzip2
      curl
      libsodium
      libssh
      libxml2
      openssl
      stdenv.cc.cc
      systemd
      util-linux
      xz
      zlib
      zstd
      # Packages not included in `nix-ld`'s NixOSModule
      glib
      libcxx
    ] ++ cfg.extraDependentPackages;

  makePkgConfigPath = x: makeSearchPathOutput "dev" "lib/pkgconfig" x;
  makeIncludePath = x: makeSearchPathOutput "dev" "include" x;

  nvim-depends-library = pkgs.buildEnv {
    name = "nvim-depends-library";
    paths = map lib.getLib build-dependent-pkgs;
    extraPrefix = "/lib/nvim-depends";
    pathsToLink = [ "/lib" ];
    ignoreCollisions = true;
  };
  nvim-depends-include = pkgs.buildEnv {
    name = "nvim-depends-include";
    paths = splitString ":" (makeIncludePath build-dependent-pkgs);
    extraPrefix = "/lib/nvim-depends/include";
    ignoreCollisions = true;
  };
  nvim-depends-pkgconfig = pkgs.buildEnv {
    name = "nvim-depends-pkgconfig";
    paths = splitString ":" (makePkgConfigPath build-dependent-pkgs);
    extraPrefix = "/lib/nvim-depends/pkgconfig";
    ignoreCollisions = true;
  };
  buildEnv = [
    "CPATH=${hmConfig.home.profileDirectory}/lib/nvim-depends/include"
    "CPLUS_INCLUDE_PATH=${hmConfig.home.profileDirectory}/lib/nvim-depends/include/c++/v1"
    "LD_LIBRARY_PATH=${hmConfig.home.profileDirectory}/lib/nvim-depends/lib"
    "LIBRARY_PATH=${hmConfig.home.profileDirectory}/lib/nvim-depends/lib"
    "NIX_LD_LIBRARY_PATH=${hmConfig.home.profileDirectory}/lib/nvim-depends/lib"
    "PKG_hmConfig_PATH=${hmConfig.home.profileDirectory}/lib/nvim-depends/pkgconfig"
  ];
in {
  options = {
    _custom.programs.neovim = {
      enable = mkEnableOption { };
      package = mkOption {
        type = types.package;
        default = pkgs.prevstable-neovim.neovim-unwrapped;
      };
      setBuildEnv = mkEnableOption ''
        Sets environment variables that resolve build dependencies as required by `mason.nvim` and `nvim-treesitter`
        Environment variables are only visible to `nvim` and have no effect on any parent sessions.
        Required for NixOS.
      '';
      withBuildTools = mkEnableOption ''
        Include basic build tools like `gcc` and `pkg-config`.
        Required for NixOS.
      '';
      withHaskell = mkEnableOption ''
        Enable the Haskell compiler. Set to `true` to
        use Haskell plugins.
      '';
      extraHaskellPackages = mkOption {
        type = with types;
          let fromType = listOf package;
          in coercedTo fromType (flip warn const ''
            Assigning a plain list to extraRPackages is deprecated.
                Please assign a function taking a package set as argument, so
                    extraHaskellPackages = [ pkgs.haskellPackages.xxx ];
                should be
                    extraHaskellPackages = hsPkgs: with hsPkgs; [ xxx ];
          '') (functionTo fromType);
        default = _: [ ];
        defaultText = literalExpression "ps: [ ]";
        example =
          literalExpression "hsPkgs: with hsPkgs; [ haskell-language-server ]";
        description = ''
          The extra Haskell packages required for your plugins to work.
          This option accepts a function that takes a Haskell package set as an argument,
          and selects the required Haskell packages from this package set.
          See the example for more info.
        '';
      };
      extraDependentPackages = mkOption {
        type = with types; listOf package;
        default = [ ];
        example = literalExpression "[ pkgs.openssl ]";
        description = "Extra build depends to add `LIBRARY_PATH` and `CPATH`.";
      };
    };
  };

  config = mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs;
        [ ripgrep ] ++ optionals cfg.setBuildEnv [
          nvim-depends-include
          nvim-depends-library
          nvim-depends-pkgconfig
          patchelf
        ];
      home.extraOutputsToInstall = optional cfg.setBuildEnv "nvim-depends";
      home.shellAliases.nvim =
        optionalString cfg.setBuildEnv (concatStringsSep " " buildEnv)
        + " SQLITE_CLIB_PATH=${pkgs.sqlite.out}/lib/libsqlite3.so " + "nvim";

      programs.neovim = {
        enable = true;
        package = cfg.package;

        withNodeJs = true;
        withPython3 = false;
        withRuby = true;

        extraPackages = with pkgs;
          [
            # Dependent packages used by default plugins
            doq
            sqlite
          ] ++ optionals cfg.withBuildTools [
            cargo
            clang
            cmake
            gcc
            gnumake
            ninja
            pkg-config
            yarn
          ] ++ optionals cfg.withHaskell [
            (pkgs.writeShellApplication {
              name = "stack";
              text = ''
                exec "${pkgs.stack}/bin/stack" "--extra-include-dirs=${hmConfig.home.profileDirectory}/lib/nvim-depends/include" "--extra-lib-dirs=${hmConfig.home.profileDirectory}/lib/nvim-depends/lib" "$@"
              '';
            })
            (haskellPackages.ghcWithPackages (ps:
              [
                # ghcup # ghcup is broken
              ] ++ cfg.extraHaskellPackages pkgs.haskellPackages))
          ];

        extraLuaPackages = ls: with ls; [ luarocks ];
      };
    };
  };
}
