{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?rev=b6bf1ca717b0ead86769102c2e94d591cc45ee9b";
    prevstable.url = "github:nixos/nixpkgs?rev=cd63096d6d887d689543a0b97743d28995bc9bc3";
    home-manager.url = "github:nix-community/home-manager?rev=829e89a16f4f96428d1b94e68d4c06107b5491c0";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.url = "github:oxalica/rust-overlay";
    nix-doom-emacs.url = "github:vlaci/nix-doom-emacs?rev=fee14d217b7a911aad507679dafbeaa8c1ebf5ff";
    nixpkgs-wayland.url  = "github:nix-community/nixpkgs-wayland?rev=c12dee11e4975052975db37584ce49534877be7f";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay?rev=24daa13d67d41887f47db0e17262b244cd5b1afe";
  };

  outputs = inputs:
    let
      mkSystem = pkgs: system: hostname:
        pkgs.lib.nixosSystem {
          system = system;
          modules = [(./. + "/hosts/${hostname}")];
          specialArgs = { inherit inputs; };
        };
    in
    {
      nixosConfigurations = {
        desktop = mkSystem inputs.nixpkgs "x86_64-linux" "desktop";
        desktop-sway = mkSystem inputs.nixpkgs "x86_64-linux" "desktop-sway";
        desktop-gnome = mkSystem inputs.nixpkgs "x86_64-linux" "desktop-gnome";
        asus-vivobook = mkSystem inputs.nixpkgs "x86_64-linux" "asus-vivobook";
      };
    };
}
