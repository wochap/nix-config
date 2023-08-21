{ fetchzip, lib, cmake, pkg-config, dbus, rustPlatform, installShellFiles
, freetype, makeWrapper, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "onagre";
  version = "1.0.0-alpha.0";

  src = fetchFromGitHub {
    owner = "oknozor";
    repo = pname;
    rev = "8d4ffe9f7f38cb2d1eb3023a128856c209100cf1";
    sha256 = "sha256-mL4kOSwJIhIY8BMGpdPS76WRFFL+ndMl5c0ANyt/jjY=";
  };

  cargoSha256 = "sha256-IOhAGrAiT2mnScNP7k7XK9CETUr6BjGdQVdEUvTYQT4=";

  doCheck = false;

  nativeBuildInputs =
    [ cmake pkg-config installShellFiles makeWrapper freetype ];

  preConfigure = ''
    export PKG_CONFIG_PATH="${dbus.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"
  '';

  meta = with lib; {
    description = "Launcher";
    homepage = "https://github.com/oknozor/onagre";
    license = licenses.mit;
    # mainProgram = "hx";
    # maintainers = with maintainers; [];
  };
}
