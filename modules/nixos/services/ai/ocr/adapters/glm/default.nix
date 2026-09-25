# GLM-OCR, a vision LLM served by the local Ollama instance.
{ lib, pkgs, ... }:

let
  model = "glm-ocr:bf16";
  command = pkgs.writeShellApplication {
    name = "ocr-glm";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      gawk
      jq
    ];
    runtimeEnv.OCR_GLM_MODEL = model;
    text = builtins.readFile ./glm.sh;
  };
in
{
  config._custom.services.ai.ocr.adapterRegistry.glm = {
    label = "GLM-OCR";
    command = lib.getExe command;
    ollamaModels = [ model ];
  };
}
