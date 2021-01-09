# Common configuration
{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      # Include common configuration
      ../common.nix
    ];

  # TODO: desktop config
}
