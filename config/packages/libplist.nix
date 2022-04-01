{ lib, stdenv, autoreconfHook, fetchFromGitHub, pkg-config, enablePython ? false
, python ? null, glib }:

stdenv.mkDerivation rec {
  pname = "libplist";
  version = "2.2.5";

  src = fetchFromGitHub {
    owner = "libimobiledevice";
    repo = pname;
    rev = "106c4ee7f53ef800a82fce9638f29756e8b78640";
    sha256 = "sha256-+QY4L/Akllw+nVOnx0ymFKGh76D74hd8rtDqSAKh2AY=";
  };

  outputs = [ "bin" "dev" "out" ] ++ lib.optional enablePython "py";

  nativeBuildInputs = [ pkg-config autoreconfHook ]
    ++ lib.optionals enablePython [ python python.pkgs.cython ];

  configureFlags = if (!enablePython) then [
    "PACKAGE_VERSION=2.2.0"
    "--without-cython"
  ] else
    [ "PACKAGE_VERSION=2.2.0" ];

  propagatedBuildInputs = [ glib ];

  postFixup = lib.optionalString enablePython ''
    moveToOutput "lib/${python.libPrefix}" "$py"
  '';

  meta = with lib; {
    description =
      "A library to handle Apple Property List format in binary or XML";
    homepage = "https://github.com/libimobiledevice/libplist";
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [ infinisil ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
