{ config, pkgs, lib, ... }:

{
  options._custom.wm.calendar = { enable = lib.mkEnableOption { }; };

  imports = [ ./mixins/khal.nix ./mixins/remind.nix ./mixins/vdirsyncer.nix ];
}
