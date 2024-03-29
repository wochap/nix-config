{
  inputs = {
    # channels
    unstable.url = "github:nixos/nixpkgs?rev=b06025f1533a1e07b6db3e75151caa155d1c7eb3"; # nixos-unstable (jan 10 2024)
    stable.url = "github:nixos/nixpkgs?rev=3dc440faeee9e889fe2d1b4d25ad0f430d449356"; # nixos-23.11 (jan 10 2024)
    nixpkgs.url = "github:nixos/nixpkgs?rev=b06025f1533a1e07b6db3e75151caa155d1c7eb3"; # nixos-unstable (mar 21 2024)
    prevstable-neovim.url = "github:nixos/nixpkgs?rev=317484b1ead87b9c1b8ac5261a8d2dd748a0492d"; # NVIM v0.9.5
    prevstable-python.url = "github:nixos/nixpkgs?rev=a16f7eb56e88c8985fcc6eb81dabd6cade4e425a"; # Python v3.11.4
    prevstable-nodejs.url = "github:nixos/nixpkgs?rev=1e409aeb5a9798a36e1cca227b7f8b8f3176e04d"; # Node v20
    prevstable-gaming.url = "github:nixos/nixpkgs?rev=f8e2ebd66d097614d51a56a755450d4ae1632df1"; # nixos-unstable (feb 06 2024)

    # home-manager
    home-manager.url = "github:nix-community/home-manager?rev=1c2acec99933f9835cc7ad47e35303de92d923a4"; # master (mar 21 2024)
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # third party nixpkgs|overlays|modules
    matcha.url = "git+https://codeberg.org/QuincePie/matcha";
    matcha.inputs.nixpkgs.follows = "unstable";
    nix-gaming.url = "github:fufexan/nix-gaming?rev=1e435616e688c2b9125cd5282febcad3ab981d5e";
    nix-gaming.inputs.nixpkgs.follows = "unstable";
    nixpkgs-wayland.url  = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs?rev=e2aec559a903ee1d94fd9935b4d558803adaf5a4";
    android-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR";
    nixos-hardware.url = "github:NixOS/nixos-hardware?rev=b34a6075e9e298c4124e35c3ccaf2210c1f3a43b";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay?rev=73b284862eb33c198207ca11f8e1eb99fe086653";
    ags.url = "github:Aylur/ags?rev=b40b8d81c5543ef02caee67560ab1c13ebcee49a";
    ags.inputs.nixpkgs.follows = "unstable";
    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-alien.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "unstable";
    hyprland-plugins.url ="github:hyprwm/hyprland-plugins";
    hyprland-plugins.inputs.hyprland.follows = "hyprland";
    hyprland-xdp.url = "github:hyprwm/xdg-desktop-portal-hyprland?rev=57ab6df950970f05f833371cc4fdf1a30fccfb2f"; # v1.3.1
    hyprland-xdp.inputs.nixpkgs.follows = "unstable";
    hyprpicker.url = "github:hyprwm/hyprpicker?rev=2ef703474fb96e97e03e66e8820f213359f29382"; # (jan 13 2024)
    hyprpicker.inputs.nixpkgs.follows = "unstable";
    lobster.url = "github:justchokingaround/lobster";
    lobster.inputs.nixpkgs.follows = "nixpkgs";

    # others
    easy-effects-presets.url = "github:JackHack96/EasyEffects-Presets";
    easy-effects-presets.flake = false;

    # terminal tools
    ani-cli.url = "github:pystardust/ani-cli";
    ani-cli.flake = false;
    fuzzy-sys.url = "github:NullSense/fuzzy-sys?rev=ddd8f87bee2260f1a27bd5f9b6362a4e904e1e8f";
    fuzzy-sys.flake = false;
    kitty-scrollback-nvim.url = "github:mikesmithgh/kitty-scrollback.nvim";
    kitty-scrollback-nvim.flake = false;
    kitty-smart-scroll.url = "github:yurikhan/kitty-smart-scroll";
    kitty-smart-scroll.flake = false;
    kitty-smart-tab.url = "github:yurikhan/kitty-smart-tab";
    kitty-smart-tab.flake = false;
    powerlevel10k.url = "github:romkatv/powerlevel10k?rev=d70eedb345a9cc54b4f3e9ae09b0dbbb4edc9a39";
    powerlevel10k.flake = false;
    smart-splits-nvim.url = "github:mrjones2014/smart-splits.nvim";
    smart-splits-nvim.flake = false;
    zsh-autocomplete.url = "github:wochap/zsh-autocomplete?rev=d52da825c2b60b664f33e8d82fdfc1c3b647b753";
    zsh-autocomplete.flake = false;
    zsh-defer.url = "github:romkatv/zsh-defer?rev=1c75faff4d8584afe090b06db11991c8c8d62055";
    zsh-defer.flake = false;
    zsh-history-substring-search.url = "github:zsh-users/zsh-history-substring-search?rev=8dd05bfcc12b0cd1ee9ea64be725b3d9f713cf64";
    zsh-history-substring-search.flake = false;
    zsh-notify.url = "github:marzocchi/zsh-notify?rev=9c1dac81a48ec85d742ebf236172b4d92aab2f3f";
    zsh-notify.flake = false;
    zsh-vi-mode.url = "github:wochap/zsh-vi-mode?rev=6091e2bc63cd076f94583a6d51eda74980566d28";
    zsh-vi-mode.flake = false;
    zsh-pnpm-shell-completion.url = "github:g-plane/pnpm-shell-completion";
    zsh-pnpm-shell-completion.flake = false;
    figlet-fonts.url = "github:xero/figlet-fonts";
    figlet-fonts.flake = false;

    # themes
    mpv-osc-morden-x.url = "github:cyl0/mpv-osc-morden-x?rev=e0adf03d40403b87d106161c1f805a65bcb34738";
    mpv-osc-morden-x.flake = false;
    dracula-lsd.url = "github:dracula/lsd?rev=75f3305a2bba4dacac82b143a15d278daee28232";
    dracula-lsd.flake = false;
    catppuccin-alacritty.url = "github:catppuccin/alacritty?rev=071d73effddac392d5b9b8cd5b4b527a6cf289f9";
    catppuccin-alacritty.flake = false;
    catppuccin-amfora.url = "github:catppuccin/amfora?rev=26f6496fd2be0fe7308dfc57b9ab1e8ca5c38602";
    catppuccin-amfora.flake = false;
    catppuccin-bat.url = "github:catppuccin/bat?rev=ba4d16880d63e656acced2b7d4e034e4a93f74b1";
    catppuccin-bat.flake = false;
    catppuccin-bottom.url = "github:catppuccin/bottom?rev=c0efe9025f62f618a407999d89b04a231ba99c92";
    catppuccin-bottom.flake = false;
    catppuccin-dircolors.url = "github:wochap/dircolors";
    catppuccin-dircolors.flake = false;
    catppuccin-discord.url = "github:catppuccin/discord";
    catppuccin-discord.flake = false;
    catppuccin-kitty.url = "github:catppuccin/kitty?rev=4820b3ef3f4968cf3084b2239ce7d1e99ea04dda";
    catppuccin-kitty.flake = false;
    catppuccin-lazygit.url = "github:catppuccin/lazygit?rev=b2ecb6d41b6f54a82104879573c538e8bdaeb0bf";
    catppuccin-lazygit.flake = false;
    catppuccin-neomutt.url = "github:catppuccin/neomutt?rev=f6ce83da47cc36d5639b0d54e7f5f63cdaf69f11";
    catppuccin-neomutt.flake = false;
    catppuccin-newsboat.url = "github:catppuccin/newsboat?rev=be3d0ee1ba0fc26baf7a47c2aa7032b7541deb0f";
    catppuccin-newsboat.flake = false;
    catppuccin-qutebrowser.url = "github:catppuccin/qutebrowser?rev=78bb72b4c60b421c8ea64dd7c960add6add92f83";
    catppuccin-qutebrowser.flake = false;
    catppuccin-zathura.url = "github:catppuccin/zathura?rev=d85d8750acd0b0247aa10e0653998180391110a4";
    catppuccin-zathura.flake = false;
    catppuccin-zsh-fsh.url = "github:catppuccin/zsh-fsh?rev=7cdab58bddafe0565f84f6eaf2d7dd109bd6fc18";
    catppuccin-zsh-fsh.flake = false;
    catppuccin-tmux.url = "github:catppuccin/tmux";
    catppuccin-tmux.flake = false;
  };

  outputs = inputs:
    let
      mkLib = pkgs: system:
        let
          lib = pkgs.lib.extend (final: prev: {
            home-manager = inputs.home-manager.lib.hm;
            _custom = import ./lib {
              pkgs = import pkgs { inherit system; };
              inherit inputs;
              inherit lib;
            };
          });
        in lib;
      mkNixosSystem = pkgs: system: hostName:
        pkgs.lib.nixosSystem {
          inherit system;
          modules = [
            inputs.home-manager.nixosModules.home-manager
            inputs.nur.nixosModules.nur
            ./overlays
            ./modules/archetypes
            ./modules/home
            ./modules/nixos
            ./modules/shared
            ./packages
            (./. + "/hosts/${hostName}")
            {
              nixpkgs.config.allowUnfree = true;
              nixpkgs.config.permittedInsecurePackages =
                [ "nodejs-14.21.3" "openssl-1.1.1u" "openssl-1.1.1v" ];
              networking.hostName = hostName;
            }
          ];
          specialArgs = {
            inherit inputs;
            inherit system;
            lib = mkLib pkgs system;
            nixpkgs = pkgs;
          };
        };
    in {
      nixosConfigurations = {
        gdesktop = mkNixosSystem inputs.nixpkgs "x86_64-linux" "gdesktop";
        glegion = mkNixosSystem inputs.nixpkgs "x86_64-linux" "glegion";
      };
    };
}
