{ lib, stdenv, callPackage, fetchFromGitHub, autoreconfHook, pkg-config, avahi
}:

# let custom_libplist = libplist.override ({ enablePython = true; });
# let custom_libplist = libplist;
# let custom_libplist = callPackage ./libplist.nix { };
let libplist = callPackage ./libplist2.nix { };
in with lib;
stdenv.mkDerivation rec {
  pname = "usbfluxd";
  version = "1.9.2";

  src = fetchFromGitHub {
    owner = "corellium";
    repo = pname;
    rev = "v1.0";
    sha256 = "sha256-tfAy3e2UssPlRB/8uReLS5f8N/xUUzbjs8sKNlr40T0=";
  };

  nativeBuildInputs = [ autoreconfHook pkg-config ];
  buildInputs = [ libplist avahi ];
  configureFlags = [ "--with-static-libplist=${libplist}/lib/libplist-2.0.la" ];

  meta = {
    description =
      "Redirects the standard usbmuxd socket to allow connections to local and remote usbmuxd instances so remote devices appear connected locally.";
    homepage = "https://github.com/corellium/usbfluxd";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    maintainers = with maintainers; [ ];
  };
}
