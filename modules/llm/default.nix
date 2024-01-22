{ config, pkgs, inputs, lib, ... }:

let cfg = config._custom.llm;
in {
  options._custom.llm.enable = lib.mkEnableOption;
  disabledModules = [ "services/misc/ollama.nix" ];
  imports = [ "${inputs.unstable}/nixos/modules/services/misc/ollama.nix" ];

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs.unstable.ollama;
    };

    nixpkgs.config.cudaSupport = lib.mkIf cfg.enableNvidia true;
  };
}
