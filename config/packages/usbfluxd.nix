{ lib, stdenv, fetchFromGitHub }:

with lib;
stdenv.mkDerivation rec {
  pname = "usbfluxd";
  version = "1.0";

  src = builtins.fetchTarball {
    url =
      "https://github.com/corellium/usbfluxd/releases/download/v1.0/usbfluxd-x86_64-libc6-libdbus13.tar.gz";
    sha256 = "012m6jzn6s12wq0qrbmyy4qw1rv76gcd32nkq75l7y2qzhn63afl";
  };

  phases = [ "installPhase" "patchPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src/usbfluxctl $out/bin/usbfluxctl
    cp $src/usbfluxd $out/bin/usbfluxd
    # chmod +x $out/bin/usbfluxctl
    # chmod +x $out/bin/usbfluxd
  '';

  # src = fetchFromGitHub {
  #   owner = "corellium";
  #   repo = pname;
  #   rev = "v${version}";
  #   sha256 = "sha256-tfAy3e2UssPlRB/8uReLS5f8N/xUUzbjs8sKNlr40T0=";
  # };

  # nativeBuildInputs = [ autoreconfHook pkg-config ];
  # buildInputs = [ libplist ];

  meta = {
    description =
      "Redirects the standard usbmuxd socket to allow connections to local and remote usbmuxd instances so remote devices appear connected locally.";
    homepage = "https://github.com/corellium/usbfluxd";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    maintainers = with maintainers; [ ];
  };
}
