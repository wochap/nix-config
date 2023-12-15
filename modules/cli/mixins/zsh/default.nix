{ config, pkgs, lib, inputs, _customLib, ... }:

let
  cfg = config._custom.cli.zsh;
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};
  relativeSymlink = path:
    config.home-manager.users.${userName}.lib.file.mkOutOfStoreSymlink
    (_customLib.runtimePath config._custom.globals.configDirectory path);
in {
  options._custom.cli.zsh = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    users.users.${userName}.shell = pkgs.zsh;

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      enableGlobalCompInit = false;
      promptInit = "";
      # enableLsColors = false;
    };

    home-manager.users.${userName} = {
      xdg.configFile = {
        "zsh/nix-store/command-not-found.sh".source = "${hmConfig.programs.nix-index.package}/etc/profile.d/command-not-found.sh";
        "zsh/key-bindings-vi.zsh".source = ./key-bindings-vi.zsh;
        "fsh/catppuccin-mocha.ini".source =
          "${inputs.catppuccin-zsh-fsh}/themes/catppuccin-mocha.ini";
      };

      programs.zsh = {
        enable = true;
        dotDir = ".config/zsh";
        envExtra = ''
          # make word movement commands to stop at every character except:
          # WORDCHARS="*?_-.[]~=/&;!#$%^(){}<>"
          export WORDCHARS="_*"
        '';
        initExtraBeforeCompInit = ''
          source ${relativeSymlink ./plugins.zsh}
        '';
        initExtra = ''
          source ${relativeSymlink ./config.zsh}
          source ${relativeSymlink ./functions.zsh}
        '';
        enableCompletion = false;
        enableAutosuggestions = false;
        # syntaxHighlighting.enable = false;
        history = {
          ignoreDups = false;
          expireDuplicatesFirst = true;
          extended = true;
          ignoreSpace = true;
          save = 1000000000;
          size = 1000000000;
          # Shares current history file between all sessions as soon as shell closes
          share = true;
          # TODO: add ignorePatterns
        };
        dirHashes = {
          nxc = "$HOME/nix-config";
          nxs = "/nix/store";
          dl = "$HOME/Downloads";
        };
      };

      # programs.carapace.enableZshIntegration = true;
      # programs.thefuck.enableZshIntegration = true;
      programs.starship.enableZshIntegration = false; # enabled by default
      programs.zoxide.enableZshIntegration = false; # zinit takes care of this
      programs.dircolors.enableZshIntegration = true;
      programs.navi.enableZshIntegration = false; # zinit takes care of this
      programs.nix-index.enableZshIntegration = false; # zinit takes care of this
    };
  };
}
