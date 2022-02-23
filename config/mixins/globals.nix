{ config, pkgs, lib, inputs, ... }:

let
  isHidpi = config._isHidpi;
  isXorg = config._displayServer == "xorg";
in {
  fonts = { sans = "JetBrainsMono Nerd Font"; };

  cursor = {
    name = "capitaine-cursors";
    package = pkgs.capitaine-cursors;
    # 16, 32, 48 or 64
    size = if (isHidpi && isXorg) then 64 else 32;
  };

  theme = {
    name = "Dracula";
    package = pkgs.dracula-theme;
  };
}
