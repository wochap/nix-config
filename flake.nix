{
  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware?rev=fb1682bab43b9dd8daf43ae28f09e44541ce33a2";
    unstable.url = "github:nixos/nixpkgs?rev=5181d5945eda382ff6a9ca3e072ed6ea9b547fee";
    nixpkgs.url = "github:nixos/nixpkgs?rev=2f06b87f64bc06229e05045853e0876666e1b023"; # nixos-21.11
    prevstable.url = "github:nixos/nixpkgs?rev=88dcc4ff3ba0a78b829ffd2c6d7c4499bf675419";
    home-manager.url = "github:nix-community/home-manager?rev=7244c6715cb8f741f3b3e1220a9279e97b2ed8f5"; # release-21.11
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.url = "github:oxalica/rust-overlay";
    nix-doom-emacs.url = "github:vlaci/nix-doom-emacs?rev=fee14d217b7a911aad507679dafbeaa8c1ebf5ff";
    nixpkgs-wayland.url  = "github:nix-community/nixpkgs-wayland?rev=1be0382761e59978d46c4a2a6fed0193f474751f";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay?rev=d9495602fc4d11f1048a810b4020d627184fcf06";
    nixpkgs-darwin.url = "github:nixos/nixpkgs?rev=3960078a2007e3662fc9c93637ee043ccdc7285e";
    darwin.url = "github:lnl7/nix-darwin?rev=17fbc68a6110edbff67e55f7450230a697ecb17e";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    home-manager-darwin.url = "github:nix-community/home-manager?rev=48f2b381dd397ec88040d3354ac9c036739ba139";
    home-manager-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs?rev=e2aec559a903ee1d94fd9935b4d558803adaf5a4";
    android-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
    # Bar (macos)
    spacebar = {
      url = "github:cmacrae/spacebar?rev=79257bae525059be5230e86df96b3b3f1a3ed0a7";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    # WM
    yabai-src = {
      url = "github:koekeishiya/yabai?rev=a4030e771f76d4f135f5b830eedd7234592df51e";
      flake = false;
    };

    ohmyzsh.url = "github:ohmyzsh/ohmyzsh?rev=c6e7f8905fb61b927f12f43fb57f8c514cd48a67";
    ohmyzsh.flake = false;

    ptsh.url = "github:jszczerbinsky/ptSh?rev=737685cf64dcd00572d3997a6f2b514219156288";
    ptsh.flake = false;
    nixpkgs-s2k.url = "github:wochap/nixpkgs-s2k?rev=2c28f8564721673073923823f4761b0f7e34cc65";
    flix-tools.url = "github:ThamognyaKodi/FlixTools?rev=76640494cf7ded9ecb8a4ac11249eb86839c5501";
    flix-tools.flake = false;
    ani-cli.url = "github:pystardust/ani-cli?rev=cbbcb3463b8706c27726db3f34bccf954cd37863";
    ani-cli.flake = false;
    mpv-osc-morden-x.url = "github:cyl0/mpv-osc-morden-x?rev=e0adf03d40403b87d106161c1f805a65bcb34738";
    mpv-osc-morden-x.flake = false;
    zsh-vi-mode.url = "github:jeffreytse/zsh-vi-mode?rev=462c032389c30a1c53226890d83c7465af92b249";
    zsh-vi-mode.flake = false;
    dracula-discord.url = "github:dracula/betterdiscord?rev=6e9151fc3b013ae3c3961c45f11c0cd8d934f4be";
    dracula-discord.flake = false;
    dracula-kitty.url = "github:dracula/kitty?rev=eeaa86a730e3d38649053574dc60a74ce06a01bc";
    dracula-kitty.flake = false;
    dracula-amfora.url = "github:dracula/amfora?rev=6e3fde02006707dc0a7b4677b0d4f40f52ed6227";
    dracula-amfora.flake = false;
    dracula-mutt.url = "github:dracula/mutt?rev=8e512a73d519b2d503b4771fbc58c67f232ce7e0";
    dracula-mutt.flake = false;
    dracula-icons-theme.url = "github:m4thewz/dracula-icons?rev=2d3c83caa8664e93d956cfa67a0f21418b5cdad8";
    dracula-icons-theme.flake = false;
    dracula-gtk-theme.url = "github:dracula/gtk?rev=18bb561588866e71ed2ef5176c2e4797c58f2655";
    dracula-gtk-theme.flake = false;
    ranger.url = "github:ranger/ranger?rev=7cbdd92a66e5f0d08672b4b9fc36492a7dc1eed6";
    ranger.flake = false;
    nnn.url = "github:jarun/nnn?rev=b8b0bab4266a635519f605c2e3e193e392674273";
    nnn.flake = false;
    dracula-sublime.url = "github:dracula/sublime?rev=09faa29057c3c39e9a45f3a51a5e262375e3bf9f";
    dracula-sublime.flake = false;
    dracula-xresources.url = "github:dracula/xresources?rev=49765e34adeebca381db1c3e5516b856ff149c93";
    dracula-xresources.flake = false;
    dracula-zsh-syntax-highlighting.url = "github:dracula/zsh-syntax-highlighting?rev=47ba26d2d4912a1b8de066e589633ff1963c5621";
    dracula-zsh-syntax-highlighting.flake = false;
    fzf-tab.url = "github:Aloxaf/fzf-tab?rev=e85f76a3af3b6b6b799ad3d64899047962b9ce52";
    fzf-tab.flake = false;
    nonicons.url = "github:yamatsum/nonicons?rev=6e4984bcb18e122a5f7588a482cb07f459b55a86";
    nonicons.flake = false;
    ncmpcpp-ueberzug.url = "github:tam-carre/ncmpcpp-ueberzug?rev=9bd9121d9ba0ac49106b34f792c3445a07643a19";
    ncmpcpp-ueberzug.flake = false;
    fontpreview-ueberzug.url = "github:OliverLew/fontpreview-ueberzug?rev=77a094c0fa846badb16e50616aa2c3635867d76a";
    fontpreview-ueberzug.flake = false;
    dracula-betterdiscord.url = "github:dracula/betterdiscord?rev=835bc3a15aba03ae10248d6a06ea8704e9cd4382";
    dracula-betterdiscord.flake = false;
  };

  outputs = inputs:
    let
      mkSystem = pkgs: system: hostname:
        pkgs.lib.nixosSystem {
          system = system;
          modules = [
            ./modules
            (./. + "/hosts/${hostname}")
          ];
          specialArgs = { inherit inputs; inherit system; nixpkgs = pkgs; };
        };
    in
    {
      nixosConfigurations = {
        desktop = mkSystem inputs.nixpkgs "x86_64-linux" "desktop";
        desktop-sway = mkSystem inputs.nixpkgs "x86_64-linux" "desktop-sway";
        desktop-gnome = mkSystem inputs.nixpkgs "x86_64-linux" "desktop-gnome";
        asus-vivobook = mkSystem inputs.nixpkgs "x86_64-linux" "asus-vivobook";
        mbp-nixos = mkSystem inputs.nixpkgs "x86_64-linux" "mbp-nixos";
        asus-old = mkSystem inputs.nixpkgs "x86_64-linux" "asus-old";
      };
      darwinConfigurations."mbp-darwin" = inputs.darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = [
          ./modules
          ./hosts/mbp-darwin
        ];
        specialArgs = { inherit inputs; nixpkgs = inputs.nixpkgs-darwin; };
      };
    };
}
