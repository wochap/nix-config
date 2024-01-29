{ channels, ... }:

final: prev: {
  inherit (channels.unstable) linuxPackages_6_6;
}

