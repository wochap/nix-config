{
  inputs = {
    # channels
    nixpkgs.url = "github:nixos/nixpkgs?rev=6c90912761c43e22b6fb000025ab96dd31c971ff"; # nixos-24.11 (25 dec 2024)
    nixpkgs-unstable.url = "github:nixos/nixpkgs?rev=23e89b7da85c3640bbc2173fe04f4bd114342367"; # nixos-unstable (22 nov 2024)
    nixpkgs-master.url = "github:nixos/nixpkgs?rev=3b998b4adb33a0a8f1a340a66a6757b206d6d3b7"; # master (05 jan 2025)
    nixpkgs-24-11-small.url = "github:nixos/nixpkgs?rev=c3b08708334cca32db70df24516608e73f645136"; # nixos-24.11-small (04 dec 2024)
    nixpkgs-24-05.url = "github:nixos/nixpkgs?rev=e8c38b73aeb218e27163376a2d617e61a2ad9b59"; # nixos-24.05 (21 nov 2024)
    prevstable-nix.url = "github:nixos/nixpkgs?rev=3dc440faeee9e889fe2d1b4d25ad0f430d449356"; # nixos-23.11 (10 jan 2024)
    prevstable-chrome.url = "github:nixos/nixpkgs?rev=9357f4f23713673f310988025d9dc261c20e70c6"; # nixos-unstable (25 sep 2024)
    prevstable-neovim.url = "github:nixos/nixpkgs?rev=799ba5bffed04ced7067a91798353d360788b30d"; # NVIM v0.10.1
    prevstable-python.url = "github:nixos/nixpkgs?rev=a16f7eb56e88c8985fcc6eb81dabd6cade4e425a"; # Python v3.11.4
    prevstable-nodejs.url = "github:nixos/nixpkgs?rev=1e409aeb5a9798a36e1cca227b7f8b8f3176e04d"; # Node v20
    prevstable-gaming.url = "github:nixos/nixpkgs?rev=c5187508b11177ef4278edf19616f44f21cc8c69"; # nixos-unstable (08 may 2024)
    prevstable-microsoft-identity-broker.url = "github:liff/nixpkgs?rev=caee0feb9ffe39364d39c54cd9c07bf477b64bff";
    prevstable-intune.url = "github:nixos/nixpkgs?rev=a3c0b3b21515f74fd2665903d4ce6bc4dc81c77c"; # nixos-unstable (16 oct 2024)

    # home-manager
    home-manager.url = "github:nix-community/home-manager?rev=80b0fdf483c5d1cb75aaad909bd390d48673857f"; # release-24.11 (25 dec 2024)
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # third party nixpkgs|overlays|modules
    chaotic.url = "github:chaotic-cx/nyx?rev=d9d59a2819215227199b5eeab06a7e5fb56681f7"; # nyxpkgs-unstable (16 nov 2024)
    chaotic.inputs.nixpkgs.follows = "nixpkgs-unstable";
    matcha.url = "git+https://codeberg.org/QuincePie/matcha";
    matcha.inputs.nixpkgs.follows = "nixpkgs";
    nix-gaming.url = "github:fufexan/nix-gaming?rev=1e435616e688c2b9125cd5282febcad3ab981d5e";
    nix-gaming.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-wayland.url  = "github:nix-community/nixpkgs-wayland?rev=52b72b12c456a5c0c87c40941ef79335e8d61104"; # master (03 sep 2024)
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs?rev=e2aec559a903ee1d94fd9935b4d558803adaf5a4";
    android-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR";
    nixos-hardware.url = "github:NixOS/nixos-hardware?rev=672ac2ac86f7dff2f6f3406405bddecf960e0db6"; # master (22 nov 2024)
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay?rev=9822e0611d49ae70278ac20c9d7b68e4797b2fab";
    ags.url = "github:Aylur/ags?rev=bb91f7c8fdd2f51c79d3af3f2881cacbdff19f60"; # v1.8.2
    ags.inputs.nixpkgs.follows = "nixpkgs";
    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-alien.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = "github:hyprwm/Hyprland?rev=12f9a0d0b93f691d4d9923716557154d74777b0a"; # v0.45.2
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    hyprland-plugins.url ="github:hyprwm/hyprland-plugins?rev=844eb98250da448e17471f20beed23a5f5d33a3a"; # v0.45
    hyprland-plugins.inputs.hyprland.follows = "hyprland";
    hyprpicker.url = "github:hyprwm/hyprpicker?rev=116cec14a552191a9ad69ca96252ca12ecfa9826"; # v0.4.1
    hyprpicker.inputs.nixpkgs.follows = "nixpkgs";
    hyprlock.url = "github:hyprwm/hyprlock?rev=3d63d9b129d5def270bc8a2471347e6f97274e2b"; # v0.6.1
    hyprlock.inputs.nixpkgs.follows = "nixpkgs";
    pyprland.url = "github:hyprland-community/pyprland?rev=af680d6d17f1d72ee335e1067e28dce3799f80f6"; # (26 aug 2024)
    pyprland.inputs.nixpkgs.follows = "nixpkgs";
    lobster.url = "github:justchokingaround/lobster";
    lobster.inputs.nixpkgs.follows = "nixpkgs";
    scenefx.url = "github:wlrfx/scenefx?rev=87c0e8b6d5c86557a800445e8e4c322f387fe19c"; # main (17 feb 2024)
    scenefx.inputs.nixpkgs.follows = "nixpkgs";
    wayfreeze.url = "github:Jappie3/wayfreeze?rev=dcbe2690ce41a286ef1eed54747bac47cee6dc2c"; # master (20 sep 2024)
    wayfreeze.inputs.nixpkgs.follows = "nixpkgs";
    arkenfox.url = "github:dwarfmaster/arkenfox-nixos";
    arkenfox.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.url = "github:MarceColl/zen-browser-flake?rev=96dffb45b36141261e97a8f83438e4c88911fefa";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    ucodenix.url = "github:e-tho/ucodenix?rev=7d7586d3fcd07e147c0dba9291b2473e060c4c98";

    # others
    easy-effects-presets.url = "github:JackHack96/EasyEffects-Presets";
    easy-effects-presets.flake = false;
    retroarch-shaders.url = "github:libretro/glsl-shaders";
    retroarch-shaders.flake = false;
    reversal-extra.url = "github:wochap/Reversal-Extra?rev=6cefd4307eefb28ba44b5d991ffa43e346392632";
    reversal-extra.flake = false;
    wluma.url = "github:maximbaz/wluma?rev=d6462471b98697643bae6feab2c8eb4468fc71ef"; # 4.5.1
    wluma.flake = false;

    # terminal tools
    fuzzy-sys.url = "github:NullSense/fuzzy-sys?rev=ddd8f87bee2260f1a27bd5f9b6362a4e904e1e8f";
    fuzzy-sys.flake = false;
    kitty-scrollback-nvim.url = "github:mikesmithgh/kitty-scrollback.nvim?rev=3f430ff8829dc2b0f5291d87789320231fdb65a1"; # (20 aug 2024)
    kitty-scrollback-nvim.flake = false;
    kitty-smart-scroll.url = "github:yurikhan/kitty-smart-scroll";
    kitty-smart-scroll.flake = false;
    kitty-smart-tab.url = "github:yurikhan/kitty-smart-tab";
    kitty-smart-tab.flake = false;
    powerlevel10k.url = "github:romkatv/powerlevel10k?rev=35833ea15f14b71dbcebc7e54c104d8d56ca5268";
    powerlevel10k.flake = false;
    smart-splits-nvim.url = "github:mrjones2014/smart-splits.nvim?rev=4a231987665d3c6e02ca88833d050e918afe3e1e"; # 1.8.1
    smart-splits-nvim.flake = false;
    zsh-autocomplete.url = "github:wochap/zsh-autocomplete?rev=d52da825c2b60b664f33e8d82fdfc1c3b647b753";
    zsh-autocomplete.flake = false;
    zsh-defer.url = "github:romkatv/zsh-defer?rev=1c75faff4d8584afe090b06db11991c8c8d62055";
    zsh-defer.flake = false;
    zsh-history-substring-search.url = "github:zsh-users/zsh-history-substring-search?rev=8dd05bfcc12b0cd1ee9ea64be725b3d9f713cf64";
    zsh-history-substring-search.flake = false;
    zsh-notify.url = "github:marzocchi/zsh-notify?rev=9c1dac81a48ec85d742ebf236172b4d92aab2f3f";
    zsh-notify.flake = false;
    zsh-vi-mode.url = "github:wochap/zsh-vi-mode?rev=bf1fecda457e230cf35ebf89c0e0f60eb0c559c0";
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
    catppuccin-alacritty.url = "github:catppuccin/alacritty";
    catppuccin-alacritty.flake = false;
    catppuccin-amfora.url = "github:catppuccin/amfora";
    catppuccin-amfora.flake = false;
    catppuccin-bat.url = "github:catppuccin/bat";
    catppuccin-bat.flake = false;
    catppuccin-bottom.url = "github:catppuccin/bottom";
    catppuccin-bottom.flake = false;
    catppuccin-dircolors.url = "github:wochap/dircolors";
    catppuccin-dircolors.flake = false;
    catppuccin-discord.url = "github:catppuccin/discord";
    catppuccin-discord.flake = false;
    catppuccin-kitty.url = "github:catppuccin/kitty";
    catppuccin-kitty.flake = false;
    catppuccin-lazygit.url = "github:catppuccin/lazygit";
    catppuccin-lazygit.flake = false;
    catppuccin-delta.url = "github:catppuccin/delta";
    catppuccin-delta.flake = false;
    catppuccin-neomutt.url = "github:catppuccin/neomutt";
    catppuccin-neomutt.flake = false;
    catppuccin-newsboat.url = "github:catppuccin/newsboat";
    catppuccin-newsboat.flake = false;
    catppuccin-qutebrowser.url = "github:catppuccin/qutebrowser";
    catppuccin-qutebrowser.flake = false;
    catppuccin-zathura.url = "github:catppuccin/zathura";
    catppuccin-zathura.flake = false;
    catppuccin-zsh-fsh.url = "github:catppuccin/zsh-fsh";
    catppuccin-zsh-fsh.flake = false;
    catppuccin-tmux.url = "github:catppuccin/tmux";
    catppuccin-tmux.flake = false;
    catppuccin-mpv.url = "github:catppuccin/mpv";
    catppuccin-mpv.flake = false;
    catppuccin-foot.url = "github:catppuccin/foot";
    catppuccin-foot.flake = false;
    catppuccin-obs.url = "github:catppuccin/obs";
    catppuccin-obs.flake = false;
    catppuccin-hyprland.url = "github:catppuccin/hyprland";
    catppuccin-hyprland.flake = false;
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
            inputs.chaotic.nixosModules.default
            inputs.ucodenix.nixosModules.default
            ./overlays
            ./modules/archetypes
            ./modules/nixos
            ./modules/shared
            ./packages
            (./. + "/hosts/${hostName}")
            {
              nixpkgs.config.allowUnfree = true;
              nixpkgs.config.permittedInsecurePackages = [
                "freeimage-unstable-2021-11-01"
                "nodejs-14.21.3"
                "openssl-1.1.1u"
                "openssl-1.1.1v"
              ];
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
