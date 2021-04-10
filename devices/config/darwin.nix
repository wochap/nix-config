{ config, lib, pkgs, ... }:

let
  # localPkgs = import ./packages { pkgs = pkgs; };
  home-manager = builtins.fetchGit {
    url = "https://github.com/nix-community/home-manager.git";
    rev = "22f6736e628958f05222ddaadd7df7818fe8f59d";
    ref = "release-20.09";
  };
in
{
  imports = [
    # Install home-manager
    (import "${home-manager}/nix-darwin")

    ./users/gean-darwin.nix
  ];

  # https://discourse.nixos.org/t/using-mkif-with-nested-if/5221/4
  # https://discourse.nixos.org/t/best-resources-for-learning-about-the-nixos-module-system/1177/4
  # https://nixos.org/manual/nixos/stable/index.html#sec-option-types
  options = {
    _displayServer = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "xorg"; # xorg, wayland
      description = "Display server type, used by common config files.";
    };
  };

  config = {
    _displayServer = "darwin";

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 4;

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      lorri
      direnv
      fzf
    ];

    environment.variables = {
      # TERM = "xterm-kitty";
      TERMINFO_DIRS = "${pkgs.kitty.terminfo.outPath}/share/terminfo";
    };

    # XXX: Copied verbatim from https://github.com/iknow/nix-channel/blob/7bf3584e0bef531836050b60a9bbd29024a1af81/darwin-modules/lorri.nix
    launchd.user.agents = {
      "lorri" = {
        serviceConfig = {
          WorkingDirectory = (builtins.getEnv "HOME");
          EnvironmentVariables = { };
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "/var/tmp/lorri.log";
          StandardErrorPath = "/var/tmp/lorri.log";
        };
        script = ''
          source ${config.system.build.setEnvironment}
          exec ${pkgs.lorri}/bin/lorri daemon
        '';
      };
    };

    environment = {
      etc = {
        "open_url.sh" = {
          source = ./scripts/open_url.sh;
        };
        "sudoers.d/10-nix-commands".text = ''
          %admin ALL=(ALL:ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild, \
                                        /run/current-system/sw/bin/nix*, \
                                        /run/current-system/sw/bin/ln, \
                                        /nix/store/*/activate, \
                                        /bin/launchctl

        '';
      };
      shellAliases = {
        gc = "git clone";
        glo = "git pull origin";
        gpo = "git push origin";
        ll = "ls -l";
      };
    };

    fonts = {
      enableFontDir = true;
      fonts = with pkgs; [
        fira-code

        (nerdfonts.override {
          fonts = [
            "FiraCode"
            "FiraMono"
            "Hack"
            "Iosevka"
          ];
        })
      ];
    };

    # Links those paths from derivations to /run/current-system/sw
    environment.pathsToLink = [
      "/share/zsh"
      "/libexec"
    ];

    # Fix https://discourse.nixos.org/t/normal-users-not-appearing-in-login-manager-lists/4619
    programs.zsh.enable = true;
    programs.fish.enable = true;

    services.yabai = {
      enable = false;
      package = pkgs.yabai;
      enableScriptingAddition = false;
      config = {

      };
      extraConfig = ''
        yabai -m config focus_follows_mouse autofocus
        yabai -m config window_topmost on
        yabai -m config window_shadow float
        yabai -m config window_border on
        yabai -m config window_border_width 2
        yabai -m config active_window_border_color 0xFFADBF8A
        yabai -m config normal_window_border_color 0xFF555555
        yabai -m config split_ratio 0.50
        yabai -m config mouse_modifier cmd
        yabai -m config mouse_action1 move
        yabai -m config mouse_action2 resize
        yabai -m config mouse_drop_action swap
      '';
    };

    services.skhd = {
      enable = false;
      skhdConfig = ''
        # Focus desktop
        cmd + 1  : yabai -m display --focus 1
        cmd + 2  : yabai -m display --focus 2
        cmd + 3  : yabai -m display --focus 3
        cmd + 4  : yabai -m display --focus 4

        # Send window to desktop
        cmd + shift - 1  : yabai -m window --space 1
        cmd + shift - 2  : yabai -m window --space 2
        cmd + shift - 3  : yabai -m window --space 3
        cmd + shift - 4  : yabai -m window --space 4

        fn + cmd - f : yabai -m window --toggle zoom-fullscreen
      '';
    };
  };
}
