{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?rev=80e6ae766ae5d928da056dee74b747660f6c1178";
    prevstable.url = "github:nixos/nixpkgs?rev=cd63096d6d887d689543a0b97743d28995bc9bc3";
    home-manager.url = "github:nix-community/home-manager?rev=5559ef002306dde0093f3d329725259cada9ed41";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.url = "github:oxalica/rust-overlay";
    nix-doom-emacs.url = "github:vlaci/nix-doom-emacs?rev=fee14d217b7a911aad507679dafbeaa8c1ebf5ff";
    nixpkgs-wayland.url  = "github:nix-community/nixpkgs-wayland?rev=c12dee11e4975052975db37584ce49534877be7f";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
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
      };
    };
}
