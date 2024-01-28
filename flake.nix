{
  inputs = {
    # channels
    unstable.url = "github:nixos/nixpkgs?rev=317484b1ead87b9c1b8ac5261a8d2dd748a0492d"; # nixos-unstable (jan 10 2024)
    nixpkgs.url = "github:nixos/nixpkgs?rev=3dc440faeee9e889fe2d1b4d25ad0f430d449356"; # nixos-23.11 (jan 10 2024)
    prevstable-neovim.url = "github:nixos/nixpkgs?rev=317484b1ead87b9c1b8ac5261a8d2dd748a0492d"; # NVIM v0.9.5
    prevstable-python.url = "github:nixos/nixpkgs?rev=a16f7eb56e88c8985fcc6eb81dabd6cade4e425a"; # Python v3.11.4
    prevstable-nodejs.url = "github:nixos/nixpkgs?rev=1e409aeb5a9798a36e1cca227b7f8b8f3176e04d"; # Node v20
    prevstable-kitty.url = "github:adamcstephens/nixpkgs?rev=05825f7d60ddd24709926e2d5edd1e2cc33113ad"; # kitty 0.31.0
    prevstable-waybar.url = "github:adamcstephens/nixpkgs?rev=8cfef6986adfb599ba379ae53c9f5631ecd2fd9c"; # waybar 0.9.24
    prevstable-ollama-webui.url = "github:malteneuss/nixpkgs?rev=d48979f4e62d5e98a171f8c0ebf839997ea714f0";

    # home-manager
    home-manager.url = "github:nix-community/home-manager?rev=5f0ab0eedc6ede69beb8f45561ffefa54edc6e65"; # release-23.11 (jan 10 2024)
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # third party nixpkgs|overlays|modules
    nixpkgs-wayland.url  = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs?rev=e2aec559a903ee1d94fd9935b4d558803adaf5a4";
    android-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR";
    nixos-hardware.url = "github:NixOS/nixos-hardware?rev=b34a6075e9e298c4124e35c3ccaf2210c1f3a43b";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay?rev=ac772de590d661e08d9bdd0a2d8f15daec3b2499";
    ags.url = "github:Aylur/ags";
    ags.inputs.nixpkgs.follows = "nixpkgs";
    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-alien.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "unstable";
    hyprland-plugins.url ="github:hyprwm/hyprland-plugins";
    hyprland-plugins.inputs.hyprland.follows = "hyprland";
    xdg-portal-hyprland.url = "github:hyprwm/xdg-desktop-portal-hyprland?rev=6a5de92769d5b7038134044053f90e7458f6a197"; # (jan 13 2024)
    xdg-portal-hyprland.inputs.nixpkgs.follows = "hyprland";
    hyprpicker.url = "github:hyprwm/hyprpicker?rev=2ef703474fb96e97e03e66e8820f213359f29382"; # (jan 13 2024)
    hyprpicker.inputs.nixpkgs.follows = "hyprland";
    lobster.url = "github:justchokingaround/lobster";
    lobster.inputs.nixpkgs.follows = "nixpkgs";

    # terminal tools
    zsh-vi-mode.url = "github:wochap/zsh-vi-mode?rev=0619e6bb711226e738494e49842c5249a2205a0d";
    zsh-vi-mode.flake = false;
    smart-splits-nvim.url = "github:mrjones2014/smart-splits.nvim";
    smart-splits-nvim.flake = false;
    kitty-scrollback-nvim.url = "github:mikesmithgh/kitty-scrollback.nvim";
    kitty-scrollback-nvim.flake = false;
    kitty-smart-scroll.url = "github:yurikhan/kitty-smart-scroll";
    kitty-smart-scroll.flake = false;
    kitty-smart-tab.url = "github:yurikhan/kitty-smart-tab";
    kitty-smart-tab.flake = false;
    fuzzy-sys.url = "github:NullSense/fuzzy-sys?rev=ddd8f87bee2260f1a27bd5f9b6362a4e904e1e8f";
    fuzzy-sys.flake = false;
    powerlevel10k.url = "github:romkatv/powerlevel10k?rev=d70eedb345a9cc54b4f3e9ae09b0dbbb4edc9a39";
    powerlevel10k.flake = false;
    zsh-autocomplete.url = "github:wochap/zsh-autocomplete?rev=d52da825c2b60b664f33e8d82fdfc1c3b647b753";
    zsh-autocomplete.flake = false;
    zsh-history-substring-search.url = "github:zsh-users/zsh-history-substring-search?rev=8dd05bfcc12b0cd1ee9ea64be725b3d9f713cf64";
    zsh-history-substring-search.flake = false;
    zsh-notify.url = "github:marzocchi/zsh-notify?rev=9c1dac81a48ec85d742ebf236172b4d92aab2f3f";
    zsh-notify.flake = false;
    zsh-defer.url = "github:romkatv/zsh-defer?rev=1c75faff4d8584afe090b06db11991c8c8d62055";
    zsh-defer.flake = false;

    # cli
    ani-cli.url = "github:pystardust/ani-cli";
    ani-cli.flake = false;

    # themes
    mpv-osc-morden-x.url = "github:cyl0/mpv-osc-morden-x?rev=e0adf03d40403b87d106161c1f805a65bcb34738";
    mpv-osc-morden-x.flake = false;

    # dracula theme
    dracula-lsd.url = "github:dracula/lsd?rev=75f3305a2bba4dacac82b143a15d278daee28232";
    dracula-lsd.flake = false;

    # catppuccin theme
    catppuccin-qutebrowser.url = "github:catppuccin/qutebrowser?rev=78bb72b4c60b421c8ea64dd7c960add6add92f83";
    catppuccin-qutebrowser.flake = false;
    catppuccin-alacritty.url = "github:catppuccin/alacritty?rev=3c808cbb4f9c87be43ba5241bc57373c793d2f17";
    catppuccin-alacritty.flake = false;
    catppuccin-lazygit.url = "github:catppuccin/lazygit?rev=b2ecb6d41b6f54a82104879573c538e8bdaeb0bf";
    catppuccin-lazygit.flake = false;
    catppuccin-bat.url = "github:catppuccin/bat?rev=ba4d16880d63e656acced2b7d4e034e4a93f74b1";
    catppuccin-bat.flake = false;
    catppuccin-kitty.url = "github:catppuccin/kitty?rev=4820b3ef3f4968cf3084b2239ce7d1e99ea04dda";
    catppuccin-kitty.flake = false;
    catppuccin-zsh-fsh.url = "github:catppuccin/zsh-fsh?rev=7cdab58bddafe0565f84f6eaf2d7dd109bd6fc18";
    catppuccin-zsh-fsh.flake = false;
    catppuccin-starship.url = "github:catppuccin/starship?rev=5629d2356f62a9f2f8efad3ff37476c19969bd4f";
    catppuccin-starship.flake = false;
    catppuccin-neomutt.url = "github:catppuccin/neomutt?rev=f6ce83da47cc36d5639b0d54e7f5f63cdaf69f11";
    catppuccin-neomutt.flake = false;
    catppuccin-bottom.url = "github:catppuccin/bottom?rev=c0efe9025f62f618a407999d89b04a231ba99c92";
    catppuccin-bottom.flake = false;
    catppuccin-zathura.url = "github:catppuccin/zathura?rev=d85d8750acd0b0247aa10e0653998180391110a4";
    catppuccin-zathura.flake = false;
    catppuccin-newsboat.url = "github:catppuccin/newsboat?rev=be3d0ee1ba0fc26baf7a47c2aa7032b7541deb0f";
    catppuccin-newsboat.flake = false;
    catppuccin-amfora.url = "github:catppuccin/amfora?rev=26f6496fd2be0fe7308dfc57b9ab1e8ca5c38602";
    catppuccin-amfora.flake = false;
    catppuccin-discord.url = "github:catppuccin/discord";
    catppuccin-discord.flake = false;
    catppuccin-dircolors.url = "github:wochap/dircolors";
    catppuccin-dircolors.flake = false;
  };

  outputs = inputs:
    let
      # https://github.com/nix-community/home-manager/issues/257#issuecomment-1646557848
      _customLib = rec {
        inherit (inputs.nixpkgs) lib;
        runtimePath = runtimeRoot: path:
          let
            rootStr = toString inputs.self;
            pathStr = toString path;
          in assert lib.assertMsg (lib.hasPrefix rootStr pathStr)
            "${pathStr} does not start with ${rootStr}";
          runtimeRoot + lib.removePrefix rootStr pathStr;
      };
      inherit (inputs.nixpkgs.lib) nixosSystem;
      mkSystem = systemFn: pkgs: system: hostname:
        systemFn {
          inherit system;
          modules = [
            ./modules
            ./packages
            (./. + "/hosts/${hostname}")
          ];
          specialArgs = { inherit inputs; inherit system; nixpkgs = pkgs; inherit _customLib; };
        };
    in
    {
      nixosConfigurations = {
        desktop = mkSystem nixosSystem inputs.nixpkgs "x86_64-linux" "desktop";
        asus-vivobook = mkSystem nixosSystem inputs.nixpkgs "x86_64-linux" "asus-vivobook";
        legion = mkSystem nixosSystem inputs.nixpkgs "x86_64-linux" "legion";
        asus-old = mkSystem nixosSystem inputs.nixpkgs "x86_64-linux" "asus-old";
      };
    };
}
