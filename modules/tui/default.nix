{ config, pkgs, lib, ... }:

{
  imports = [ ./mixins/nix-direnv ./mixins/wtf ./mixins/lynx ];
}
