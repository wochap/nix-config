{ config, pkgs, lib, ... }:

let
  yabai-focus = pkgs.writeShellScriptBin "yabai-focus.sh"
    (builtins.readFile ./scripts/yabai-focus.sh);
in {
  config = {
    environment = {
      systemPackages = with pkgs; [ yabai-focus ];

      etc = {
        "scripts/projects/yabai-nd.sh" = {
          source = ./scripts/yabai-nd.sh;
          # mode = "0755";
        };
      };
    };
  };
}
