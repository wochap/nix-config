# RapidOCR with the PP-OCRv6 ONNX models, run on the CPU.
{ lib, pkgs, ... }:

let
  python = pkgs.python3.withPackages (_: [ pkgs._custom.rapidocr ]);
  entrypoint = pkgs.writeText "rapidocr-text.py" (builtins.readFile ./rapidocr-text.py);
  command = pkgs.writeShellApplication {
    name = "ocr-rapid";
    text = ''
      exec ${python}/bin/python ${entrypoint} "$@"
    '';
  };
in
{
  config._custom.services.ai.ocr.screenAdapters.rapid = {
    label = "RapidOCR";
    command = lib.getExe command;
  };
}
