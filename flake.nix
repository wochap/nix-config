{
  inputs = {
    # channels
    nixpkgs.url = "github:nixos/nixpkgs?rev=4792576cb003c994bd7cc1edada3129def20b27d"; # nixos-25.05 (07 jun 2025)
    nixpkgs-unstable.url = "github:nixos/nixpkgs?rev=c87b95e25065c028d31a94f06a62927d18763fdf"; # nixos-unstable (20 jul 2025)
    nixpkgs-master.url = "github:nixos/nixpkgs?rev=58f3c8b331269776bf25b8725a2ea9c184bd6fe5"; # master (18 aug 2025)
    nixpkgs-24-11.url = "github:nixos/nixpkgs?rev=b75693fb46bfaf09e662d09ec076c5a162efa9f6"; # nixos-24.11 (20 mar 2025)
    prevstable-chrome.url = "github:nixos/nixpkgs?rev=4792576cb003c994bd7cc1edada3129def20b27d"; # nixos-25.05 (07 jun 2025)
    prevstable-neovim.url = "github:nixos/nixpkgs?rev=84577351974736371ddb9d36d788b6e34247b891"; # master (02 sep 2025)
    prevstable-python.url = "github:nixos/nixpkgs?rev=6c90912761c43e22b6fb000025ab96dd31c971ff"; # Python v3.11.11
    prevstable-nodejs.url = "github:nixos/nixpkgs?rev=1e409aeb5a9798a36e1cca227b7f8b8f3176e04d"; # Node v20
    prevstable-gaming.url = "github:nixos/nixpkgs?rev=4792576cb003c994bd7cc1edada3129def20b27d"; # nixos-25.05 (07 jun 2025)
    prevstable-intune.url = "github:kahlstrm/nixpkgs?rev=9c71553dfe5e77329fc4f3b4f18f9483b52f0ccc"; # master (05 jun 2025)
    prevstable-msedge.url = "github:Daholli/nixpkgs?rev=fe6e79e571fa7eb7693cda131b68fe9891078adf"; # master (07 jun 2025)

    # home-manager
    home-manager.url = "github:nix-community/home-manager?rev=7b5a978e00273b8676c530c03d315f5b75fae564"; # release-25.05 (25 jul 2025)
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # third party nixpkgs|overlays|modules
    chaotic.url = "github:chaotic-cx/nyx?rev=491e18a40a19d7c9d63d92bcbfb6d3f316631b00"; # nyxpkgs-unstable (17 may 2025)
    chaotic.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nix-gaming.url = "github:fufexan/nix-gaming?rev=bafc474d9d2ac0f97411b48679b00811fff39cfa"; # master (17 may 2024)
    nix-gaming.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-wayland.url  = "github:nix-community/nixpkgs-wayland?rev=52b72b12c456a5c0c87c40941ef79335e8d61104"; # master (03 sep 2024)
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs?rev=e2aec559a903ee1d94fd9935b4d558803adaf5a4"; # (08 mar 2022)
    android-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR";
    nixos-hardware.url = "github:NixOS/nixos-hardware?rev=9368056b73efb46eb14fd4667b99e0f81b805f28"; # master (05 aug 2025)
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay?rev=b34ae92bd1dc371e8ba59262108677d96879e2ce"; # (07 jun 2025)
    ags.url = "github:Aylur/ags?rev=237601999d65a4663bcbab934f4f6ce1f579d728"; # v1 (26 jul 2025)
    ags.inputs.nixpkgs.follows = "nixpkgs";
    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-alien.inputs.nixpkgs.follows = "nixpkgs";
    # everytime you update hyprland flake, run `sudo nix flake lock --update-input hyprland`
    hyprland.url = "github:hyprwm/Hyprland?rev=46174f78b374b6cea669c48880877a8bdcf7802f"; # v0.51
    hyprland.inputs.nixpkgs.follows = "nixpkgs-unstable";
    hyprland-plugins.url ="github:hyprwm/hyprland-plugins?rev=d723e5b153b7990d36e62a425bda3768c41dd9eb"; # v0.50.0
    hyprland-plugins.inputs.hyprland.follows = "hyprland";
    hyprspace.url = "github:KZDKM/Hyprspace?rev=d626e9e23d4f19cb8f66c356e5a830066204ecc3"; # (10 aug 2025)
    hyprspace.inputs.hyprland.follows = "hyprland";
    hyprpicker.url = "github:hyprwm/hyprpicker?rev=980ebd486b8a4c2ac1670286f38d163db1e38cd9"; # v0.4.5
    hyprpicker.inputs.nixpkgs.follows = "nixpkgs";
    hyprsunset.url = "github:hyprwm/hyprsunset?rev=962f519df793ea804810b1ddebfc8a88b80a845c"; # v0.3.1
    hyprsunset.inputs.nixpkgs.follows = "nixpkgs";
    # everytime you update hyprland flake, `sudo nix flake lock --update-input hyprlock`
    hyprlock.url = "github:hyprwm/hyprlock?rev=bdf0ef82822a4c434b79c8d315518c9db9a10f34"; # v0.9.1
    hyprlock.inputs.nixpkgs.follows = "nixpkgs";
    pyprland.url = "github:hyprland-community/pyprland?rev=33dc0f5c4bef4b3f094e641f0e31c6e3f9fe5a2d"; # v2.4.7
    pyprland.inputs.nixpkgs.follows = "nixpkgs";
    hyprmag.url = "github:SIMULATAN/hyprmag?rev=a58f3715ab1b097343bda0918ebc450ffcae4627"; # main (20 jul 2025)
    hyprmag.inputs.nixpkgs.follows = "nixpkgs";
    hyprgrass.url = "github:horriblename/hyprgrass?rev=427690aec574fec75f5b7b800ac4a0b4c8e4b1d5"; # v0.8.1
    lobster.url = "github:justchokingaround/lobster";
    lobster.inputs.nixpkgs.follows = "nixpkgs";
    scenefx.url = "github:wochap/scenefx?rev=5991e3979dd81349f35eecb7f03cbcbece6bc24d"; # main (17 feb 2024)
    scenefx.inputs.nixpkgs.follows = "nixpkgs";
    wayfreeze.url = "github:Jappie3/wayfreeze?rev=dc41ae1662c4c760f3deba9f826ba605e99971cc"; # master (08 jul 2025)
    wayfreeze.inputs.nixpkgs.follows = "nixpkgs";
    arkenfox.url = "github:dwarfmaster/arkenfox-nixos";
    arkenfox.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.url = "github:0xc000022070/zen-browser-flake?rev=ebeabdb79392f3dfac8c6019754e76997e4d5dfa"; # 1.13t#1747739974
    cpu-microcodes.url = "github:platomav/CPUMicrocodes/ec5200961ecdf78cf00e55d73902683e835edefd";
    cpu-microcodes.flake = false;
    ucodenix.url = "github:e-tho/ucodenix?rev=98c0b8ec151ee6495711d2dd902112b4f2a30ceb"; # main (04 aug 2025)
    ucodenix.inputs.cpu-microcodes.follows = "cpu-microcodes";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    figma-linux.url = "github:HelloWorld017/figma-linux-nixos?rev=11d282f45c5acb90660db7d0d989fe0d9eec8813"; # v0.11.5
    figma-linux.inputs.nixpkgs.follows = "nixpkgs";
    quickshell.url = "github:quickshell-mirror/quickshell?rev=a5431dd02dc23d9ef1680e67777fed00fe5f7cda"; # v0.2.0
    quickshell.inputs.nixpkgs.follows = "nixpkgs";
    rod.url = "github:leiserfg/rod?rev=05601eaa09f08830613c41b6bdc35e34336880a5"; # master (12 aug 2025)
    rod.inputs.nixpkgs.follows = "nixpkgs";

    # others
    easy-effects-presets.url = "github:JackHack96/EasyEffects-Presets";
    easy-effects-presets.flake = false;
    retroarch-shaders.url = "github:libretro/glsl-shaders";
    retroarch-shaders.flake = false;
    reversal-extra.url = "github:wochap/Reversal-Extra";
    reversal-extra.flake = false;
    wluma.url = "github:maximbaz/wluma?rev=ea4c8c6ae689655950ccbc1c2c214f5c0e4562ee"; # 4.9.0
    wluma.flake = false;

    # terminal tools
    fuzzy-sys.url = "github:NullSense/fuzzy-sys?rev=ddd8f87bee2260f1a27bd5f9b6362a4e904e1e8f"; # master (06 apr 2023)
    fuzzy-sys.flake = false;
    kitty-scrollback-nvim.url = "github:mikesmithgh/kitty-scrollback.nvim?rev=fd9f83f3f1141ef65de73fbe962f6c606ef02da8"; # v6.2.2
    kitty-scrollback-nvim.flake = false;
    kitty-smart-scroll.url = "github:yurikhan/kitty-smart-scroll";
    kitty-smart-scroll.flake = false;
    kitty-smart-tab.url = "github:yurikhan/kitty-smart-tab";
    kitty-smart-tab.flake = false;
    powerlevel10k.url = "github:romkatv/powerlevel10k?rev=35833ea15f14b71dbcebc7e54c104d8d56ca5268"; # v1.20.0
    powerlevel10k.flake = false;
    smart-splits-nvim.url = "github:mrjones2014/smart-splits.nvim?rev=2b5dda43b3de5d13b56c4606f7d19db78637e527"; # v2.0.3
    smart-splits-nvim.flake = false;
    zsh-autocomplete.url = "github:wochap/zsh-autocomplete?rev=5aedb496754c867e949c144e19c74bfccbbef1a2"; # (16 aug 2025)
    zsh-autocomplete.flake = false;
    zsh-defer.url = "github:romkatv/zsh-defer?rev=1c75faff4d8584afe090b06db11991c8c8d62055"; # (05 nov 2023)
    zsh-defer.flake = false;
    zsh-history-substring-search.url = "github:zsh-users/zsh-history-substring-search?rev=87ce96b1862928d84b1afe7c173316614b30e301"; # (17 may 2025)
    zsh-history-substring-search.flake = false;
    zsh-notify.url = "github:marzocchi/zsh-notify?rev=9c1dac81a48ec85d742ebf236172b4d92aab2f3f"; # (30 apr 2023)
    zsh-notify.flake = false;
    zsh-vi-mode.url = "github:wochap/zsh-vi-mode?rev=425e4293e243bccf8da3439a25a7699fe4ab3b1b"; # (26 jul 2025)
    zsh-vi-mode.flake = false;
    zsh-pnpm-shell-completion.url = "github:g-plane/pnpm-shell-completion";
    zsh-pnpm-shell-completion.flake = false;
    figlet-fonts.url = "github:wochap/figlet-fonts";
    figlet-fonts.flake = false;
    ipwebcam-gst.url = "github:agarciadom/ipwebcam-gst?rev=5a02ffae8597ab1cc7461f096f86ca233f925a07";
    ipwebcam-gst.flake = false;
    tmux-sessionx.url = "github:omerxx/tmux-sessionx?rev=ac9b0ec219c2e36ce6beb3f900ef852ba8888095"; # (27 apr 2024)
    nnn-cppath.url = "github:raffaem/nnn-cppath?rev=1d3f4f64d43533d203af82c61f4a93afc8d5aaf5"; # (31 dec 2023)
    nnn-cppath.flake = false;

    # themes
    catppuccin-lsd.url = "github:catppuccin/lsd";
    catppuccin-lsd.flake = false;
    catppuccin-cava.url = "github:catppuccin/cava";
    catppuccin-cava.flake = false;
    catppuccin-qt5ct.url = "github:catppuccin/qt5ct";
    catppuccin-qt5ct.flake = false;
    catppuccin-fzf.url = "github:catppuccin/fzf";
    catppuccin-fzf.flake = false;
    catppuccin-adw.url = "github:claymorwan/catppuccin";
    catppuccin-adw.flake = false;
    catppuccin-grub.url = "github:catppuccin/grub";
    catppuccin-grub.flake = false;
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
            inputs.nur.nixosModules.nur
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
                "freeimage-3.18.0-unstable-2024-04-18"
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
