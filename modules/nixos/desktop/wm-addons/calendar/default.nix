{ lib, ... }:

{
  options._custom.desktop.calendar.enable = lib.mkEnableOption { };

  imports = [ ./mixins/khal.nix ./mixins/remind.nix ./mixins/vdirsyncer.nix ];
}
