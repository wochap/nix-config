{
  inputs = {
    # channels
    unstable.url = "github:nixos/nixpkgs?rev=ecf7c683c21655a2c90bec49ce726aa6615a7d28"; # master (02 aug 2024)
    stable.url = "github:nixos/nixpkgs?rev=3dc440faeee9e889fe2d1b4d25ad0f430d449356"; # nixos-23.11 (jan 10 2024)
    nixpkgs.url = "github:nixos/nixpkgs?rev=9f918d616c5321ad374ae6cb5ea89c9e04bf3e58"; # nixos-unstable (02 aug 2024)
    prevstable-nixpkgs.url = "github:nixos/nixpkgs?rev=ad0b5eed1b6031efaed382844806550c3dcb4206"; # nixos-unstable (jul 19 2024)
    prevstable-neovim.url = "github:nixos/nixpkgs?rev=52ec9ac3b12395ad677e8b62106f0b98c1f8569d"; # NVIM v0.10.1
    prevstable-python.url = "github:nixos/nixpkgs?rev=a16f7eb56e88c8985fcc6eb81dabd6cade4e425a"; # Python v3.11.4
    prevstable-nodejs.url = "github:nixos/nixpkgs?rev=1e409aeb5a9798a36e1cca227b7f8b8f3176e04d"; # Node v20
    prevstable-gaming.url = "github:nixos/nixpkgs?rev=c5187508b11177ef4278edf19616f44f21cc8c69"; # nixos-unstable (may 08 2024)
    prevstable-rubymine.url = "github:mevatron/nixpkgs?rev=6ae3ced59e52bb3fd99d82913e299273a3d4f18a"; # v2024.1.1

    # home-manager
    home-manager.url = "github:nix-community/home-manager?rev=0a30138c694ab3b048ac300794c2eb599dc40266"; # master (jul 04 2024)
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # third party nixpkgs|overlays|modules
    matcha.url = "git+https://codeberg.org/QuincePie/matcha";
    matcha.inputs.nixpkgs.follows = "unstable";
    nix-gaming.url = "github:fufexan/nix-gaming?rev=1e435616e688c2b9125cd5282febcad3ab981d5e";
    nix-gaming.inputs.nixpkgs.follows = "unstable";
    nixpkgs-wayland.url  = "github:nix-community/nixpkgs-wayland?rev=34d357829660a9f84e4f23ef06e461b9cca89212"; # master (aug 11 2024)
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs?rev=e2aec559a903ee1d94fd9935b4d558803adaf5a4";
    android-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR";
    nixos-hardware.url = "github:NixOS/nixos-hardware?rev=6e253f12b1009053eff5344be5e835f604bb64cd"; # master (jul 04 2024)
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay?rev=9822e0611d49ae70278ac20c9d7b68e4797b2fab";
    ags.url = "github:Aylur/ags?rev=11150225e62462bcd431d1e55185e810190a730a";
    ags.inputs.nixpkgs.follows = "nixpkgs";
    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-alien.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1&rev=918d8340afd652b011b937d29d5eea0be08467f5"; # v0.41.2 (jul 04 2024)
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    hyprland-plugins.url ="github:hyprwm/hyprland-plugins?rev=98cb18c6fcfe8196ef4150d09fbae305b7bb2954"; # (jul 04 2024)
    hyprland-plugins.inputs.hyprland.follows = "hyprland";
    hyprpicker.url = "github:hyprwm/hyprpicker?rev=b0974381f996f92dc191e6b03adf7d581061619b"; # (jul 04 2024)
    hyprpicker.inputs.nixpkgs.follows = "nixpkgs";
    pyprland.url = "github:hyprland-community/pyprland?rev=a609ceeea7b1aeedf6e82d7224f9c96ccbac5342"; # 2.4.0 (jul 04 2024)
    pyprland.inputs.nixpkgs.follows = "nixpkgs";
    lobster.url = "github:justchokingaround/lobster";
    lobster.inputs.nixpkgs.follows = "nixpkgs";
    scenefx.url = "github:wlrfx/scenefx?rev=7a7c35750239bd117931698b121a072f30bc1cbe";
    scenefx.inputs.nixpkgs.follows = "nixpkgs";
    wayfreeze.url = "github:Jappie3/wayfreeze?rev=37ef9e456c87601ed4e06f36f437f688083d61cf";
    wayfreeze.inputs.nixpkgs.follows = "nixpkgs";

    # others
    easy-effects-presets.url = "github:JackHack96/EasyEffects-Presets";
    easy-effects-presets.flake = false;
    retroarch-shaders.url = "github:libretro/glsl-shaders";
    retroarch-shaders.flake = false;
    reversal-extra.url = "github:wochap/Reversal-Extra?rev=9358e4dff06223e051e013a612de2b949d043f38";
    reversal-extra.flake = false;
    wluma.url = "github:maximbaz/wluma?rev=f7aa9967231ef5c821eeea7e43a9929ace0c4fa8";
    wluma.flake = false;

    # terminal tools
    fuzzy-sys.url = "github:NullSense/fuzzy-sys?rev=ddd8f87bee2260f1a27bd5f9b6362a4e904e1e8f";
    fuzzy-sys.flake = false;
    kitty-scrollback-nvim.url = "github:mikesmithgh/kitty-scrollback.nvim";
    kitty-scrollback-nvim.flake = false;
    kitty-smart-scroll.url = "github:yurikhan/kitty-smart-scroll";
    kitty-smart-scroll.flake = false;
    kitty-smart-tab.url = "github:yurikhan/kitty-smart-tab";
    kitty-smart-tab.flake = false;
    powerlevel10k.url = "github:romkatv/powerlevel10k?rev=35833ea15f14b71dbcebc7e54c104d8d56ca5268";
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
    figlet-fonts.url = "github:wochap/figlet-fonts";
    figlet-fonts.flake = false;
    ipwebcam-gst.url = "github:agarciadom/ipwebcam-gst?rev=5a02ffae8597ab1cc7461f096f86ca233f925a07";
    ipwebcam-gst.flake = false;
    tmux-sessionx.url = "github:omerxx/tmux-sessionx?rev=ac9b0ec219c2e36ce6beb3f900ef852ba8888095";
    nnn-cppath.url = "github:raffaem/nnn-cppath?rev=1d3f4f64d43533d203af82c61f4a93afc8d5aaf5";
    nnn-cppath.flake = false;

    # themes
    dracula-lsd.url = "github:dracula/lsd?rev=75f3305a2bba4dacac82b143a15d278daee28232";
    dracula-lsd.flake = false;
    catppuccin-grub.url = "github:catppuccin/grub";
    catppuccin-grub.flake = false;
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
    catppuccin-lazygit.url = "github:catppuccin/lazygit?rev=30bff2e6d14ca12a09d71e5ce4e6a086b3e48aa6";
    catppuccin-lazygit.flake = false;
    catppuccin-delta.url = "github:catppuccin/delta";
    catppuccin-delta.flake = false;
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
    catppuccin-mpv.url = "github:catppuccin/mpv";
    catppuccin-mpv.flake = false;
    catppuccin-foot.url = "github:catppuccin/foot";
    catppuccin-foot.flake = false;
    catppuccin-obs.url = "github:catppuccin/obs";
    catppuccin-obs.flake = false;
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
