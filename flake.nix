{
  inputs = {
    nixpkgs.url = "github:colemickens/nixpkgs/cmpkgs";
    prevstable.url = "github:nixos/nixpkgs?rev=cd63096d6d887d689543a0b97743d28995bc9bc3";
    home-manager.url = "github:nix-community/home-manager?rev=148d85ee8303444fb0116943787aa0b1b25f94df";
    nix-doom-emacs.url = "github:vlaci/nix-doom-emacs?rev=fee14d217b7a911aad507679dafbeaa8c1ebf5ff";
    nixpkgs-wayland.url  = "github:nix-community/nixpkgs-wayland?rev=51930bd55223f3d9e4428f6750e4ff80cca2815d";

    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    let
      mkSystem = pkgs: system: hostname:
        pkgs.lib.nixosSystem {
          system = system;
          modules = [(./. + "/devices/${hostname}.nix")];
          specialArgs = { inherit inputs; };
        };
    in
    {
      nixosConfigurations = {
        desktop = mkSystem inputs.nixpkgs "x86_64-linux" "desktop";
      };
    };
}
