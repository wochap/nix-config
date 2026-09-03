{
  fetchurl,
  python3,
}:

let
  pythonPackages = python3.pkgs;
in
pythonPackages.buildPythonPackage rec {
  pname = "rapidocr";
  version = "3.9.2";
  format = "wheel";

  src = fetchurl {
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
    models="$out/${python3.sitePackages}/rapidocr/models"
    test -f "$models/PP-OCRv6_det_small.onnx"
    test -f "$models/ch_ppocr_mobile_v2.0_cls_mobile.onnx"
    test -f "$models/PP-OCRv6_rec_small.onnx"
    test -f "$models/ppocrv6_dict.txt"
  '';

  pythonImportsCheck = [
    "rapidocr"
    "rapidocr.main"
  ];
}
