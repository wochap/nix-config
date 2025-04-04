# source: https://github.com/SimonYde/pix2tex.nix/blob/master/nix/default.nix
# source: https://github.com/CHN-beta/mirror-test/blob/2bc088ce85dde041382310dc8ebf395505770aa5/local/pkgs/pix2tex/default.nix
{ pkgs, python3Packages, fetchFromGitHub, enableCuda ? false }:

let
  timm_0_5_4 = pkgs.callPackage ./timm.nix { inherit pkgs; };
  x-transformers = pkgs.callPackage ./x-transformers.nix { inherit pkgs; };
in with python3Packages;
buildPythonPackage {
  name = "pix2tex";

  src = fetchFromGitHub {
    owner = "lukas-blecher";
    repo = "LaTeX-OCR";
    rev = "5c1ac929bd19a7ecf86d5fb8d94771c8969fcb80";
    hash = "sha256-tzfvJaE9UJe9Fy/eTMczJaMbk8qfSrqWvriVKO7+SKQ=";
  };

  propagatedBuildInputs = with pkgs; [
    # general dependencies:
    tqdm
    munch
    torch
    (opencv.override { inherit enableCuda; })
    requests
    einops
    transformers
    x-transformers
    tokenizers
    numpy
    pillow
    pyyaml
    pandas
    timm_0_5_4
    albumentations

    # gui
    pyqt6
    pyqt6-webengine
    pyside6
    pynput
    screeninfo

    # api
    streamlit
    fastapi
    uvicorn
    python-multipart

    # # training
    # python-levenshtein
    # torchtext
    # imagesize

    # highlight
    pygments
  ];

  patchPhase = ''
    # Fix checkpoint download/load path to use ~/.cache/pix2tex
    substituteInPlace ./pix2tex/model/checkpoints/get_latest_checkpoint.py \
      --replace "path = os.path.dirname(__file__)" $'path = os.path.join(os.environ["HOME"], ".cache", "pix2tex")\n    if not os.path.exists(path):\n        os.makedirs(path)'

    # Fix default weights path in __main__ and ensure os is imported correctly
    substituteInPlace ./pix2tex/__main__.py \
      --replace "default='checkpoints/weights.pth'" "default=os.path.join(os.environ['HOME'], '.cache', 'pix2tex', 'weights.pth')" \
      --replace $'    import os\n' "" \
      --replace "def main():" $'def main():\n    import os\n'

    # Add weights_only=True to torch.load in cli.py line 84
    substituteInPlace ./pix2tex/cli.py \
      --replace 'torch.load(self.args.checkpoint, map_location=self.args.device)' \
                'torch.load(self.args.checkpoint, map_location=self.args.device, weights_only=True)'

    # Add weights_only=True to torch.load in cli.py line 90
    substituteInPlace ./pix2tex/cli.py \
      --replace "torch.load(os.path.join(os.path.dirname(self.args.checkpoint), 'image_resizer.pth'), map_location=self.args.device)" \
                "torch.load(os.path.join(os.path.dirname(self.args.checkpoint), 'image_resizer.pth'), map_location=self.args.device, weights_only=True)"
  '';
}

