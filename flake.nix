{
  inputs = {
    # channels
    nixpkgs.url = "github:nixos/nixpkgs?rev=0ad6f47ea4fe188f4bc8f0380f93ae8523337c6c"; # nixos-26.05 (10 jul 2026)
    nixpkgs-unstable.url = "github:nixos/nixpkgs?rev=0bb7ec54c8483066ec9d7720e780a5caa71f8612"; # nixos-unstable (10 jul 2026)
    nixpkgs-master.url = "github:nixos/nixpkgs?rev=12ccf3e6a73accd6f85aaf857b909d1d63563064"; # master (10 jul 2026)
    prevstable-mesa.url = "github:nixos/nixpkgs?rev=0ad6f47ea4fe188f4bc8f0380f93ae8523337c6c"; # mesa v26.1.4
    prevstable-chrome.url = "github:nixos/nixpkgs?rev=0ad6f47ea4fe188f4bc8f0380f93ae8523337c6c"; # nixos-26.05 (10 jul 2026)
    prevstable-neovim.url = "github:nixos/nixpkgs?rev=0ad6f47ea4fe188f4bc8f0380f93ae8523337c6c"; # neovim v0.12.3
    prevstable-python.url = "github:nixos/nixpkgs?rev=6c90912761c43e22b6fb000025ab96dd31c971ff"; # Python v3.11.11
    prevstable-gaming.url = "github:nixos/nixpkgs?rev=0ad6f47ea4fe188f4bc8f0380f93ae8523337c6c"; # nixos-26.05 (10 jul 2026)
    prevstable-intune.url = "github:nixos/nixpkgs?rev=0ad6f47ea4fe188f4bc8f0380f93ae8523337c6c"; # nixos-26.05 (10 jul 2026)
    prevstable-msedge.url = "github:nixos/nixpkgs?rev=0ad6f47ea4fe188f4bc8f0380f93ae8523337c6c"; # nixos-26.05 (10 jul 2026)

    # home-manager
    home-manager.url = "github:nix-community/home-manager?rev=af2beae5f0fae0a4310cc0e6aef2572f56090353"; # release-26.05 (10 jul 2026)
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # hyprland
    # everytime you update hyprland flake, run `sudo nix flake lock --update-input hyprland`
    hyprland.url = "github:hyprwm/Hyprland?rev=a0136d8c04687bb36eb8a28eb9d1ff92aea99704"; # v0.55.4
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    hyprland-plugins.url ="github:hyprwm/hyprland-plugins?rev=90e66baf99c9025b1d5e9c9e58dd3c80d0911ea2"; # v0.55.0
    hyprland-plugins.inputs.hyprland.follows = "hyprland";
    hyprspace.url = "github:KZDKM/Hyprspace?rev=c109256f5a79a8694acd6176971c4a273d32264c"; # main (10 jul 2026)
    hyprspace.inputs.hyprland.follows = "hyprland";
    hyprpicker.url = "github:hyprwm/hyprpicker?rev=8c163ce9b8a40f85babe4dd6e23a238787351164"; # v0.4.7
    hyprpicker.inputs.nixpkgs.follows = "nixpkgs";
    hyprsunset.url = "github:hyprwm/hyprsunset?rev=057feb7a724b7fc0f3a406d6db08b59734db006a"; # v0.3.3
    hyprsunset.inputs.nixpkgs.follows = "nixpkgs";
    # everytime you update hyprland flake, `sudo nix flake lock --update-input hyprlock`
    hyprlock.url = "github:hyprwm/hyprlock?rev=d75e93f8ee1721d70549d96f4d14bf2948aab70c"; # v0.9.5
    hyprlock.inputs.nixpkgs.follows = "nixpkgs";
    pyprland.url = "github:hyprland-community/pyprland?rev=b8cf62fe52f19804e34e7d3afb10df68fcfe9a3f"; # v3.4.3
    pyprland.inputs.nixpkgs.follows = "nixpkgs";
    hyprgrass.url = "github:horriblename/hyprgrass?rev=e28346f49144e058b0e2d9dc66313c0a57c3d423"; # main (10 jul 2026)
    hyprland-guiutils.url = "github:hyprwm/hyprland-guiutils?rev=c2e906261142f5dd1ee0bfc44abba23e2754c660"; # v0.2.1
    hyprland-guiutils.inputs.nixpkgs.follows = "nixpkgs";

    # third party nixpkgs|overlays|modules
    chaotic.url = "github:chaotic-cx/nyx?rev=bb52c6c8936353a03000929d37146bc636f4673f"; # main (10 jul 2026)
    chaotic.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nix-gaming.url = "github:fufexan/nix-gaming?rev=ea13b9c4aa381fba9513ebf438a38ea344320b09"; # master (10 jul 2026)
    nix-gaming.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-wayland.url  = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs?rev=e2aec559a903ee1d94fd9935b4d558803adaf5a4"; # (08 mar 2022)
    android-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR";
    nixos-hardware.url = "github:NixOS/nixos-hardware?rev=9368056b73efb46eb14fd4667b99e0f81b805f28"; # master (05 aug 2025)
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay?rev=204823393e14fede7e69cacbccdb94882ac75822"; # (10 jul 2026)
    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-alien.inputs.nixpkgs.follows = "nixpkgs";
    lobster.url = "github:justchokingaround/lobster";
    lobster.inputs.nixpkgs.follows = "nixpkgs";
    wayfreeze.url = "github:Jappie3/wayfreeze?rev=8f813abc5082e1375326ca0f888834f79f872006"; # master (10 jul 2026)
    wayfreeze.inputs.nixpkgs.follows = "nixpkgs";
    arkenfox.url = "github:dwarfmaster/arkenfox-nixos";
    arkenfox.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs-unstable";
    zen-browser.inputs.home-manager.follows = "home-manager";
    cpu-microcodes.url = "github:platomav/CPUMicrocodes?rev=49aa6bd56d1019c1e8b47321d2eb66913a2da876"; # master (10 jul 2026)
    cpu-microcodes.flake = false;
    ucodenix.url = "github:e-tho/ucodenix?rev=5c9a1202884f7f455119f35df03c66f6a98ce5f9"; # main (10 jul 2026)
    ucodenix.inputs.cpu-microcodes.follows = "cpu-microcodes";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    quickshell.url = "github:quickshell-mirror/quickshell?rev=59e9c47b0eb48a9e4bcf9631fa062ee939bd2e83"; # v0.3.0
    quickshell.inputs.nixpkgs.follows = "nixpkgs";
    rod.url = "github:leiserfg/rod?rev=5d378a226a3a0108f657eccc3dc457cf3e374b73"; # master (10 jul 2026)
    rod.inputs.nixpkgs.follows = "nixpkgs";
    antigravity-nix.url = "github:jacopone/antigravity-nix";
    antigravity-nix.inputs.nixpkgs.follows = "nixpkgs";

    # others
    easy-effects-presets.url = "github:JackHack96/EasyEffects-Presets";
    easy-effects-presets.flake = false;
    retroarch-shaders.url = "github:libretro/glsl-shaders";
    retroarch-shaders.flake = false;
    reversal-extra.url = "github:wochap/Reversal-Extra";
    reversal-extra.flake = false;
    wluma.url = "github:maximbaz/wluma?rev=259a874af6b4d854073d340cccb1852f63635fd3"; # 4.11.1
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
    zsh-auto-notify.url = "github:wochap/zsh-auto-notify";
    zsh-auto-notify.flake = false;
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
            inputs.ucodenix.nixosModules.default
            ./overlays
            ./modules/archetypes
            ./modules/nixos
            ./modules/sandbox
            ./modules/shared
            ./packages
            (./. + "/hosts/${hostName}")
            {
              nixpkgs.config.allowUnfree = true;
              nixpkgs.config.permittedInsecurePackages = [
                "electron-39.8.10" # required by bitwarden-desktop
                "nodejs-slim-20.20.2" # required by redisinsight
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
        gasus = mkNixosSystem inputs.nixpkgs "x86_64-linux" "gasus";
        gdesktop = mkNixosSystem inputs.nixpkgs "x86_64-linux" "gdesktop";
        glegion = mkNixosSystem inputs.nixpkgs "x86_64-linux" "glegion";
      };
    };
}
