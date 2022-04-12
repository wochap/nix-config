{ lib, stdenv, callPackage, fetchFromGitHub, autoreconfHook, pkg-config, avahi
, libplist }:

with lib;
stdenv.mkDerivation rec {
  pname = "usbfluxd";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "corellium";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-tfAy3e2UssPlRB/8uReLS5f8N/xUUzbjs8sKNlr40T0=";
  };

  nativeBuildInputs = [ autoreconfHook pkg-config ];
  buildInputs = [ libplist avahi ];
  configureFlags = [ "--with-static-libplist=${libplist.out}/lib/libplist-2.0.la" ];

  meta = {
    description =
      "Redirects the standard usbmuxd socket to allow connections to local and remote usbmuxd instances so remote devices appear connected locally.";
    homepage = "https://github.com/corellium/usbfluxd";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    maintainers = with maintainers; [ ];
  };
}
