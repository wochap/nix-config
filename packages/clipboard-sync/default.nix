{ lib, fetchFromGitHub, rustPlatform, libxcb }:

rustPlatform.buildRustPackage rec {
  pname = "clipboard-sync";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "dnut";
    repo = "clipboard-sync";
    rev = version;
    sha256 = "sha256-gme5pwQrwQbk8MroF/mGYqlY6hcjM5cHKHL7Y3nlW9k=";
  };
  cargoHash = "sha256-/LGRgml+iNwoMrMCmDesCpXA1qgWKauuqM540SZMS3Y=";

  # build inputs
  buildInputs = [ libxcb ];

  # disable checks
  doCheck = false;

  # metadata
  meta = with lib; {
    homepage = "https://github.com/dnut/clipboard-sync";
    description = "clipboard-sync";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = with maintainers; [ ];
    mainProgram = "clipboard-sync";
  };
}
