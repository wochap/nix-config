{ config, pkgs, lib, inputs, ... }:

{
  fonts = { sans = "JetBrainsMono Nerd Font"; };

  cursor = {
    name = "capitaine-cursors";
    package = pkgs.capitaine-cursors;
    # 16, 32, 48 or 64
    size = 32;
  };

  theme = {
    name = "Dracula";
    package = pkgs.dracula-theme;
  };
}
