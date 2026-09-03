{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.services.ai;
  python = pkgs.python3;
  rapidocrPython = python.withPackages (_: [ pkgs._custom.rapidocr ]);
  rapidocrEntrypoint = pkgs.writeText "rapidocr-text.py" (builtins.readFile ./rapidocr-text.py);

  ocr = pkgs.writeShellApplication {
    name = "ocr";
    runtimeEnv = {
      OCR_RAPID_ENTRYPOINT = rapidocrEntrypoint;
      OCR_RAPID_PYTHON = "${rapidocrPython}/bin/python";
    };
    text = builtins.readFile ./ocr.sh;
  };
in
{
  config = lib.mkIf cfg.enableOcr {
    assertions = [
      {
        assertion = cfg.enableOllama;
        message = "_custom.services.ai.enableOcr requires _custom.services.ai.enableOllama";
      }
    ];

    environment.systemPackages = with pkgs; [
      ocr
    ];

    services.ollama.loadModels = lib.mkAfter [ "glm-ocr:bf16" ];
  };
}
