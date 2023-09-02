{
  inputs = {
    # nixpkgs channels
    unstable.url = "github:nixos/nixpkgs?rev=94d494b2f667a9c910582e1ba9648babd63550bf"; # master (aug 25 2023)
    nixpkgs.url = "github:nixos/nixpkgs?rev=a16f7eb56e88c8985fcc6eb81dabd6cade4e425a"; # nixos-23.05-small (aug 2023)
    prevstable-neovim.url = "github:nixos/nixpkgs?rev=841889913dfd06a70ffb39f603e29e46f45f0c1a"; # NVIM v0.9.1
    prevstable-mongodb.url = "github:nixos/nixpkgs?rev=88dcc4ff3ba0a78b829ffd2c6d7c4499bf675419"; # MongoDB shell version v4.2.17
    prevstable-python.url = "github:nixos/nixpkgs?rev=a16f7eb56e88c8985fcc6eb81dabd6cade4e425a"; # Python v3.11.4
    prevstable-nodejs.url = "github:nixos/nixpkgs?rev=53657afe29748b3e462f1f892287b7e254c26d77"; # Node v14.21.3
    prevstable-chrome.url = "github:nixos/nixpkgs?rev=13231eccfa1da771afa5c0807fdd73e05a1ec4e6"; # Google Chrome 114.0.5735.198
    prevstable-kernel-pkgs.url = "github:nixos/nixpkgs?rev=ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b"; # Linux 5.15.119
    prevstable-hyprland.url = "github:nixos/nixpkgs?rev=94d494b2f667a9c910582e1ba9648babd63550bf"; # master (aug 25 2023)
    nixpkgs-darwin.url = "github:nixos/nixpkgs?rev=3960078a2007e3662fc9c93637ee043ccdc7285e";
    nixpkgs-python.url = "github:cachix/nixpkgs-python?rev=dfe9a33d0d9bd31650b69c36f8fff5f2d5342393"; # main (aug 26 2023)

    # macos related
    darwin.url = "github:lnl7/nix-darwin?rev=17fbc68a6110edbff67e55f7450230a697ecb17e";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    # home-manager
    home-manager.url = "github:nix-community/home-manager?rev=2a6679aa9cc3872c29ba2a57fe1b71b3e3c5649f"; # release-23.05 (aug 2023)
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
    hyprland.url = "github:hyprwm/Hyprland?rev=116b9a80566e7956233b39697ac78c112d514c3c"; # main (aug 25 2023)
    hyprland.inputs.nixpkgs.follows = "prevstable-hyprland"; # TODO: change to nixpkgs
    hyprland-plugins.url ="github:hyprwm/hyprland-plugins?rev=e368bd15e4bfd560baa9333ad47415340c563458";
    hyprland-plugins.inputs.hyprland.url = "github:hyprwm/Hyprland?rev=2df0d034bc4a18fafb3524401eeeceaa6b23e753";
    xdg-portal-hyprland.url = "github:hyprwm/xdg-desktop-portal-hyprland?rev=e1f145d15db320fe5c5e99b90898ab87db7e8214";
    hyprpicker.url = "github:hyprwm/hyprpicker?rev=fe4535a27389624445b96450a7c338136c619c95";

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

    # dracula theme
    dracula-adw-gtk3.url = "github:lassekongo83/adw-colors?rev=b290fedc46e3dc0719b9e2455ad765afe0c6a4d7";
    dracula-adw-gtk3.flake = false;
    dracula-kitty.url = "github:dracula/kitty?rev=eeaa86a730e3d38649053574dc60a74ce06a01bc";
    dracula-kitty.flake = false;
    dracula-amfora.url = "github:dracula/amfora?rev=6e3fde02006707dc0a7b4677b0d4f40f52ed6227";
    dracula-amfora.flake = false;
    dracula-mutt.url = "github:dracula/mutt?rev=8e512a73d519b2d503b4771fbc58c67f232ce7e0";
    dracula-mutt.flake = false;
    dracula-sublime.url = "github:dracula/sublime?rev=09faa29057c3c39e9a45f3a51a5e262375e3bf9f";
    dracula-sublime.flake = false;
    dracula-zsh-syntax-highlighting.url = "github:dracula/zsh-syntax-highlighting?rev=47ba26d2d4912a1b8de066e589633ff1963c5621";
    dracula-zsh-syntax-highlighting.flake = false;
    dracula-betterdiscord.url = "github:dracula/betterdiscord?rev=835bc3a15aba03ae10248d6a06ea8704e9cd4382";
    dracula-betterdiscord.flake = false;
  };

  outputs = inputs:
    let
      inherit (inputs.nixpkgs.lib) nixosSystem;
      inherit (inputs.darwin.lib) darwinSystem;
      mkSystem = systemFn: pkgs: system: hostname:
        systemFn {
          inherit system;
          modules = [
            ./modules
            (./. + "/hosts/${hostname}")
          ];
          specialArgs = { inherit inputs; inherit system; nixpkgs = pkgs; };
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
