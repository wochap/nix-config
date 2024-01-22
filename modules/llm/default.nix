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
      ollama-webui-package = pkgs._custom.ollama-webui;
    };
    systemd.services.ollama-webui.serviceConfig.ExecStart = let
      ollamaWebuiCfg = config.services.ollama-webui;
      port = toString ollamaWebuiCfg.port;
    in lib.mkForce
    "${ollamaWebuiCfg.ollama-webui-package}/bin/ollama-webui --port ${port} --proxy http://localhost:${port}?";

    nixpkgs.config.cudaSupport = lib.mkIf cfg.enableNvidia true;
  };
}
