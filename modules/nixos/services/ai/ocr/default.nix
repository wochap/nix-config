{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.services.ai;
  python = pkgs.python3;
  pythonPackages = python.pkgs;

  rapidocr = pythonPackages.buildPythonPackage rec {
    pname = "rapidocr";
    version = "3.9.2";
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/55/ed/0ee9b9281986974be9d2406ae0134c8d7c91d2fc613f16ffda9701eeda6f/rapidocr-${version}-py3-none-any.whl";
      hash = "sha256-BNa40VH4I9kwvZGRBVX1e+qJfAxE+meUJnuUz5we+aA=";
    };

    dependencies = with pythonPackages; [
      colorlog
      numpy
      omegaconf
      onnxruntime
      opencv-python
      pillow
      pyclipper
      pyyaml
      requests
      shapely
      six
      tqdm
    ];

    postInstall = ''
      models="$out/${python.sitePackages}/rapidocr/models"
      test -f "$models/PP-OCRv6_det_small.onnx"
      test -f "$models/ch_ppocr_mobile_v2.0_cls_mobile.onnx"
      test -f "$models/PP-OCRv6_rec_small.onnx"
      test -f "$models/ppocrv6_dict.txt"
    '';

    pythonImportsCheck = [
      "rapidocr"
      "rapidocr.main"
    ];
  };

  rapidocrPython = python.withPackages (_: [ rapidocr ]);
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
