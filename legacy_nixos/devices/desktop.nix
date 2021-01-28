# Common configuration
{ config, pkgs, ... }:

let
  hostName = "gdesktop";
in
{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      # Include common configuration
      (import ../common.nix {
        inherit pkgs config hostName;
      })
    ];

  # Set hostname.
  networking = { 
    inherit hostName;
  };
  # TODO: desktop config
}
