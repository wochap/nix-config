{ lib, stdenv, fetchFromGitHub, inotify-tools, libwebp, libXft, imlib2, giflib
, libexif, conf ? null }:

with lib;

stdenv.mkDerivation rec {
  pname = "nsxiv";
  version = "28";

  src = fetchFromGitHub {
    owner = "nsxiv";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-12RmEAzZdeanrRtnan96loXT7qSjIMjcWf296XmNE+A=";
  };

  configFile =
    optionalString (conf != null) (builtins.toFile "config.def.h" conf);
  preBuild = optionalString (conf != null) "cp ${configFile} config.def.h";

  buildInputs = [ giflib imlib2 inotify-tools libXft libexif libwebp ];

  makeFlags = [ "PREFIX=${placeholder "out"}" ];

  postInstall = ''
    # install -Dt $out/share/applications sxiv.desktop
  '';

  meta = {
    description = "Simple X Image Viewer";
    homepage = "https://github.com/nsxiv/nsxiv";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    maintainers = with maintainers; [ ];
  };
}
