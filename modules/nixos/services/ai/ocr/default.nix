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
  pdfIngestPipeline = pkgs.writeText "pdf-ingest.py" (builtins.readFile ./pdf-ingest.py);

  ocr = pkgs.writeShellApplication {
    name = "ocr";
    runtimeEnv = {
      OCR_RAPID_ENTRYPOINT = rapidocrEntrypoint;
      OCR_RAPID_PYTHON = "${rapidocrPython}/bin/python";
    };
    text = builtins.readFile ./ocr.sh;
  };
  pdf-ingest = pkgs.writeShellApplication {
    name = "pdf-ingest";
    runtimeInputs = with pkgs; [
      python3
    ];
    runtimeEnv = {
      PDF_INGEST_IMAGE = "ccr-2vdh3abv-pub.cnc.bj.baidubce.com/paddlepaddle/paddleocr-vl:paddleocr3.6-nvidia-gpu-offline@sha256:6c735bdf9e758ffdd58ccc067db0c2d84e37e5e6a2cbd47156069d4d7ea5d709";
      PDF_INGEST_PIPELINE = pdfIngestPipeline;
    };
    text = builtins.readFile ./pdf-ingest.sh;
    meta.description = "Extract a PDF into a portable canonical document directory";
  };
in
{
  options._custom.services.ai.enableOcr = lib.mkEnableOption { };

  config = lib.mkIf cfg.enableOcr {
    environment.systemPackages = with pkgs; [
      ocr
      pdf-ingest
    ];

    services.ollama.loadModels = lib.mkAfter [ "glm-ocr:bf16" ];
  };
}
