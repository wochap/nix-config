{
  inputs = {
    # nixpkgs channels
    unstable.url = "github:nixos/nixpkgs?rev=4f2b18d41893ffbf9487a86a874791a681601260"; # master (aug 25 2023)
    nixpkgs.url = "github:nixos/nixpkgs?rev=1e409aeb5a9798a36e1cca227b7f8b8f3176e04d"; # nixos-23.05-small (sep 04 2023)
    prevstable-neovim.url = "github:nixos/nixpkgs?rev=e44462d6021bfe23dfb24b775cc7c390844f773d"; # NVIM v0.9.1
    prevstable-mongodb.url = "github:nixos/nixpkgs?rev=88dcc4ff3ba0a78b829ffd2c6d7c4499bf675419"; # MongoDB shell version v4.2.17
    prevstable-python.url = "github:nixos/nixpkgs?rev=a16f7eb56e88c8985fcc6eb81dabd6cade4e425a"; # Python v3.11.4
    prevstable-nodejs.url = "github:nixos/nixpkgs?rev=1e409aeb5a9798a36e1cca227b7f8b8f3176e04d"; # Node v20
    prevstable-chrome.url = "github:nixos/nixpkgs?rev=5a237aecb57296f67276ac9ab296a41c23981f56"; # Google Chrome 117.0.5938.132
    prevstable-kernel-pkgs.url = "github:nixos/nixpkgs?rev=ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b"; # Linux 5.15.119
    prevstable-hyprland.url = "github:nixos/nixpkgs?rev=94d494b2f667a9c910582e1ba9648babd63550bf"; # master (aug 25 2023)
    prevstable-kitty.url = "github:adamcstephens/nixpkgs?rev=05825f7d60ddd24709926e2d5edd1e2cc33113ad"; # kitty 0.31.0
    prevstable-waybar.url = "github:adamcstephens/nixpkgs?rev=8cfef6986adfb599ba379ae53c9f5631ecd2fd9c"; # waybar 0.9.24
    nixpkgs-darwin.url = "github:nixos/nixpkgs?rev=3960078a2007e3662fc9c93637ee043ccdc7285e";
    nixpkgs-python.url = "github:cachix/nixpkgs-python?rev=dfe9a33d0d9bd31650b69c36f8fff5f2d5342393"; # main (aug 26 2023)

    # macos related
    darwin.url = "github:lnl7/nix-darwin?rev=17fbc68a6110edbff67e55f7450230a697ecb17e";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    # home-manager
    home-manager.url = "github:nix-community/home-manager?rev=5bac4a1c06cd77cf8fc35a658ccb035a6c50cd2c"; # release-23.05 (sep 04 2023)
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-darwin.url = "github:nix-community/home-manager?rev=48f2b381dd397ec88040d3354ac9c036739ba139";
    home-manager-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    # drivers?
    nixos-hardware.url = "github:NixOS/nixos-hardware?rev=7f1836531b126cfcf584e7d7d71bf8758bb58969";

    # third party nixpkgs
    nixpkgs-wayland.url  = "github:nix-community/nixpkgs-wayland?rev=1be0382761e59978d46c4a2a6fed0193f474751f";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs?rev=e2aec559a903ee1d94fd9935b4d558803adaf5a4";
    android-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR?rev=0ba95a2c93c4965bc244c1221649d25198c7e687";

    # third party overlays/modules
    ags.url = "github:Aylur/ags";
    ags.inputs.nixpkgs.follows = "nixpkgs";
    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-alien.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = "github:hyprwm/Hyprland?rev=116b9a80566e7956233b39697ac78c112d514c3c"; # main (aug 25 2023)
    hyprland.inputs.nixpkgs.follows = "prevstable-hyprland"; # TODO: change to nixpkgs
    hyprland-plugins.url ="github:hyprwm/hyprland-plugins?rev=e368bd15e4bfd560baa9333ad47415340c563458";
    hyprland-plugins.inputs.hyprland.url = "github:hyprwm/Hyprland?rev=2df0d034bc4a18fafb3524401eeeceaa6b23e753";
    xdg-portal-hyprland.url = "github:hyprwm/xdg-desktop-portal-hyprland?rev=bb6bcf846b07fc7ed7a812414f5b6b1cf0f8742e"; # v1.2.1 (oct 09 2023)
    hyprpicker.url = "github:hyprwm/hyprpicker?rev=fe4535a27389624445b96450a7c338136c619c95";
    hyprpicker.inputs.nixpkgs.follows = "nixpkgs";
    lobster.url = "github:justchokingaround/lobster";
    lobster.inputs.nixpkgs.follows = "nixpkgs";

    # third party darwin stuff
    spacebar.url = "github:cmacrae/spacebar?rev=79257bae525059be5230e86df96b3b3f1a3ed0a7";
    spacebar.inputs.nixpkgs.follows = "nixpkgs-darwin";
    yabai-src.url = "github:koekeishiya/yabai?rev=a4030e771f76d4f135f5b830eedd7234592df51e";
    yabai-src.flake = false;

    # terminal tools
    # zsh-vi-mode.url = "github:jeffreytse/zsh-vi-mode?rev=462c032389c30a1c53226890d83c7465af92b249";
    # zsh-vi-mode.flake = false;
    # fzf-tab.url = "github:Aloxaf/fzf-tab?rev=e85f76a3af3b6b6b799ad3d64899047962b9ce52";
    # fzf-tab.flake = false;
    ncmpcpp-ueberzug.url = "github:munguua/ncmpcpp-ueberzug?rev=9bd9121d9ba0ac49106b34f792c3445a07643a19";
    ncmpcpp-ueberzug.flake = false;
    ohmyzsh.url = "github:ohmyzsh/ohmyzsh?rev=c6e7f8905fb61b927f12f43fb57f8c514cd48a67";
    ohmyzsh.flake = false;
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

    # third party cli
    ptsh.url = "github:jszczerbinsky/ptSh?rev=737685cf64dcd00572d3997a6f2b514219156288";
    ptsh.flake = false;
    ani-cli.url = "github:pystardust/ani-cli?rev=6be7f07f33f7fb746103f3eeeafd14744555cff7";
    ani-cli.flake = false;
    ranger.url = "github:ranger/ranger?rev=7cbdd92a66e5f0d08672b4b9fc36492a7dc1eed6";
    ranger.flake = false;
    nnn.url = "github:jarun/nnn?rev=b8b0bab4266a635519f605c2e3e193e392674273";
    nnn.flake = false;
    fontpreview-ueberzug.url = "github:OliverLew/fontpreview-ueberzug?rev=f10f40cba0c64a506772a0ff343cd0f57237432d";
    fontpreview-ueberzug.flake = false;

    # themes
    mpv-osc-morden-x.url = "github:cyl0/mpv-osc-morden-x?rev=e0adf03d40403b87d106161c1f805a65bcb34738";
    mpv-osc-morden-x.flake = false;
    nonicons.url = "github:yamatsum/nonicons?rev=6e4984bcb18e122a5f7588a482cb07f459b55a86";
    nonicons.flake = false;
    adw-gtk3-colors.url = "github:lassekongo83/adw-colors?rev=b290fedc46e3dc0719b9e2455ad765afe0c6a4d7";
    adw-gtk3-colors.flake = false;

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
    catppuccin-zsh-syntax-highlighting.url = "github:catppuccin/zsh-syntax-highlighting?rev=06d519c20798f0ebe275fc3a8101841faaeee8ea";
    catppuccin-zsh-syntax-highlighting.flake = false;
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
      inherit (inputs.darwin.lib) darwinSystem;
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
        desktop-sway = mkSystem nixosSystem inputs.nixpkgs "x86_64-linux" "desktop-sway";
        desktop-gnome = mkSystem nixosSystem inputs.nixpkgs "x86_64-linux" "desktop-gnome";
        asus-vivobook = mkSystem nixosSystem inputs.nixpkgs "x86_64-linux" "asus-vivobook";
        mbp-nixos = mkSystem nixosSystem inputs.nixpkgs "x86_64-linux" "mbp-nixos";
        asus-old = mkSystem nixosSystem inputs.nixpkgs "x86_64-linux" "asus-old";
      };
      darwinConfigurations = {
        mbp-darwin = mkSystem darwinSystem inputs.nixpkgs-darwin "x86_64-darwin" "mbp-darwin";
      };
    };
}
