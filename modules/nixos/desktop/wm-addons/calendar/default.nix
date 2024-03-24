{ lib, ... }:

{
  options._custom.de.calendar.enable = lib.mkEnableOption { };

  imports = [ ./mixins/khal.nix ./mixins/remind.nix ./mixins/vdirsyncer.nix ];
}
