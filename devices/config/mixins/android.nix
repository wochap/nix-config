{ config, pkgs, lib, ... }:

{
  config = {
    programs.adb.enable = true;
  };
}
