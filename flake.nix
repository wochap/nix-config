{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?rev=a0bf6b28dff054b4d95f28ff7e2d7b99b60aa027";
    prevstable.url = "github:nixos/nixpkgs?rev=cd63096d6d887d689543a0b97743d28995bc9bc3";
    home-manager.url = "github:nix-community/home-manager?rev=0b197562ab7bf114dd5f6716f41d4b5be6ccd357";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.url = "github:oxalica/rust-overlay";
    nix-doom-emacs.url = "github:vlaci/nix-doom-emacs?rev=fee14d217b7a911aad507679dafbeaa8c1ebf5ff";
    nixpkgs-wayland.url  = "github:nix-community/nixpkgs-wayland?rev=c12dee11e4975052975db37584ce49534877be7f";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay?rev=c25636a6800b5b9d5da7282d9c0c61f87343b67c";
    nixpkgs-darwin.url = "github:nixos/nixpkgs?rev=3960078a2007e3662fc9c93637ee043ccdc7285e";
    darwin.url = "github:lnl7/nix-darwin?rev=5851d9613edf8b2279746c7e5b9faac55ff17e8a";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    home-manager-darwin.url = "github:nix-community/home-manager?rev=48f2b381dd397ec88040d3354ac9c036739ba139";
    home-manager-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
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
      darwinConfigurations."mbp-darwin" = inputs.darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = [ ./hosts/mbp-darwin ];
        specialArgs = { inherit inputs; nixpkgs = inputs.nixpkgs-darwin; };
      };
    };
}
