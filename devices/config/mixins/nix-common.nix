# Used by darwin|wayland|xorg config
{ config, pkgs, lib, ... }:

let
  isHidpi = config._isHidpi;
in
{
  # https://discourse.nixos.org/t/using-mkif-with-nested-if/5221/4
  # https://discourse.nixos.org/t/best-resources-for-learning-about-the-nixos-module-system/1177/4
  # https://nixos.org/manual/nixos/stable/index.html#sec-option-types
  options = {
    _displayServer = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "xorg"; # xorg, wayland, darwin
      description = "Display server type, used by common config files.";
    };
    _isHidpi = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Flag for hidpi displays.";
    };
  };

  config = {
    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    nix = {
      gc.automatic = true;

      trustedUsers = [ "@wheel" "root" ];
    };

    # Set your time zone.
    time.timeZone = "America/Panama";

    environment = {
      shellAliases = {
        gc = "git clone";
        glo = "git pull origin";
        gpo = "git push origin";
        ll = "ls -l";
      };

      # Links those paths from derivations to /run/current-system/sw
      pathsToLink = [
        "/libexec"
      ];
    };

    # Fix https://discourse.nixos.org/t/normal-users-not-appearing-in-login-manager-lists/4619
    programs.zsh.enable = true;
    programs.fish.enable = true;
  };
}