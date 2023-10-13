{ config, pkgs, lib, ... }:

{
  imports =
    [ ./mixins/fontpreview-kik ./mixins/lynx ./mixins/nix-direnv ./mixins/wtf ];
}
