{ config, pkgs, inputs, lib, ... }:

let cfg = config._custom.llm;
in {
  options._custom.llm = {
    enable = lib.mkEnableOption { };
    enableNvidia = lib.mkEnableOption { };
  };
  disabledModules = [ "services/misc/ollama.nix" ];
  imports = [ "${inputs.unstable}/nixos/modules/services/misc/ollama.nix" ];

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs.unstable.ollama;
      # package = inputs.ollama-cuda.packages.${pkgs.system}.default;
    };

    nixpkgs.config.cudaSupport = lib.mkIf cfg.enableNvidia true;
  };
}
