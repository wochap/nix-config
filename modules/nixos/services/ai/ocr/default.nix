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
  rapidocrEntrypoint = pkgs.writeText "rapidocr-text.py" ''
    import sys

    from rapidocr import EngineType, LangCls, LangDet, LangRec, ModelType, OCRVersion, RapidOCR


    def main() -> None:
        if len(sys.argv) != 2:
            raise SystemExit("usage: rapidocr-text IMAGE")

        engine = RapidOCR(
            params={
                "Det.engine_type": EngineType.ONNXRUNTIME,
                "Det.lang_type": LangDet.CH,
                "Det.model_type": ModelType.SMALL,
                "Det.ocr_version": OCRVersion.PPOCRV6,
                "Rec.engine_type": EngineType.ONNXRUNTIME,
                "Rec.lang_type": LangRec.CH,
                "Rec.model_type": ModelType.SMALL,
                "Rec.ocr_version": OCRVersion.PPOCRV6,
                "Cls.engine_type": EngineType.ONNXRUNTIME,
                "Cls.lang_type": LangCls.CH,
                "Cls.model_type": ModelType.MOBILE,
                "Cls.ocr_version": OCRVersion.PPOCRV4,
            }
        )
        result = engine(sys.argv[1])
        texts = getattr(result, "txts", None) or ()
        sys.stdout.write("\n".join(texts))


    if __name__ == "__main__":
        main()
  '';

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
