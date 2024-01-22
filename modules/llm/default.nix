{ config, pkgs, inputs, lib, ... }:

let cfg = config._custom.llm;
in {
  options._custom.llm = {
    enable = lib.mkEnableOption { };
    enableNvidia = lib.mkEnableOption { };
  };
  disabledModules =
    [ "services/misc/ollama.nix" "services/web-apps/ollama-webui.nix" ];
  imports = [
    "${inputs.unstable}/nixos/modules/services/misc/ollama.nix"
    "${inputs.prevstable-ollama-webui}/nixos/modules/services/web-apps/ollama-webui.nix"
  ];

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs.unstable.ollama;
    };

    services.ollama-webui = {
      enable = true;
      port = 8090;
      ollama-webui-package = pkgs.prevstable-ollama-webui.ollama-webui;
    };

    nixpkgs.config.cudaSupport = lib.mkIf cfg.enableNvidia true;
  };
}
