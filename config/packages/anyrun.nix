{ lib, cmake, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "anyrun";
  version = "0.11.1";

  src = fetchFromGitHub {
    owner = "Kirottu";
    repo = pname;
    rev = "9ac2a9a2ebf5667290bf60e4e4ecc03c0caa89cc";
    sha256 = "sha256-mL4kOSwJIhIY8BMGpdPS76WRFFL+n5Ml5c0ANyt/jjY=";
  };

  cargoSha256 = "sha256-IOhAGrAiT2mnScNP7k7XK9CETU56BjGdQVdEUvTYQT4=";

  doCheck = false;

  nativeBuildInputs = [ ];

  # preConfigure = ''
  #   export PKG_CONFIG_PATH="${dbus.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"
  # '';

  meta = with lib; {
    description = "Launcher";
    homepage = "https://github.com/Kirottu/anyrun";
    license = licenses.mit;
    # mainProgram = "hx";
    # maintainers = with maintainers; [];
  };
}
