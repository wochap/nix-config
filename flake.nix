{
  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware?rev=fb1682bab43b9dd8daf43ae28f09e44541ce33a2";
    electron-stable.url = "github:nixos/nixpkgs?rev=2e15415fede3883a4bfcf35ca832fc53f525f686";
    nixpkgs.url = "github:nixos/nixpkgs?rev=88dcc4ff3ba0a78b829ffd2c6d7c4499bf675419";
    prevstable.url = "github:nixos/nixpkgs?rev=e3264bbf018dac6f55307d03407d480ca0f11016";
    home-manager.url = "github:nix-community/home-manager?rev=0b197562ab7bf114dd5f6716f41d4b5be6ccd357";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.url = "github:oxalica/rust-overlay";
    nix-doom-emacs.url = "github:vlaci/nix-doom-emacs?rev=fee14d217b7a911aad507679dafbeaa8c1ebf5ff";
    nixpkgs-wayland.url  = "github:nix-community/nixpkgs-wayland?rev=1be0382761e59978d46c4a2a6fed0193f474751f";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay?rev=4b0fe150f81a4eb5dffa0ef2b4069748ab0c4d6c";
    nixpkgs-darwin.url = "github:nixos/nixpkgs?rev=3960078a2007e3662fc9c93637ee043ccdc7285e";
    darwin.url = "github:lnl7/nix-darwin?rev=5851d9613edf8b2279746c7e5b9faac55ff17e8a";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    home-manager-darwin.url = "github:nix-community/home-manager?rev=48f2b381dd397ec88040d3354ac9c036739ba139";
    home-manager-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    ohmyzsh.url = "github:ohmyzsh/ohmyzsh?rev=c6e7f8905fb61b927f12f43fb57f8c514cd48a67";
    ohmyzsh.flake = false;

    nixpkgs-s2k.url = "github:wochap/nixpkgs-s2k?rev=2c28f8564721673073923823f4761b0f7e34cc65";
    zsh-vi-mode.url = "github:jeffreytse/zsh-vi-mode?rev=462c032389c30a1c53226890d83c7465af92b249";
    zsh-vi-mode.flake = false;
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
  };

  outputs = inputs:
    let
      mkSystem = pkgs: system: hostname:
        pkgs.lib.nixosSystem {
          system = system;
          modules = [(./. + "/hosts/${hostname}")];
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
      };
      darwinConfigurations."mbp-darwin" = inputs.darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = [ ./hosts/mbp-darwin ];
        specialArgs = { inherit inputs; nixpkgs = inputs.nixpkgs-darwin; };
      };
    };
}
