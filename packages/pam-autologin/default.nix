{ lib, stdenv, fetchurl, pam, ... }:

stdenv.mkDerivation rec {
  pname = "pam_autologin";
  version = "1.2-GGGG";

  src = fetchurl {
    url = "mirror://sourceforge/project/pam-autologin/pam_autologin-1.2.tar.gz";
    sha256 = "0p48f620b7gval88j4q7bxm8zazvad2qcpx89r6bixazw8arp5bd";
  };

  buildInputs = [ pam ];

  installPhase = ''
    mkdir -p $out/lib/security
    cp -rL ./.o/* $out/lib/security/
  '';

  meta = with lib; {
    homepage = "https://sourceforge.net/projects/pam-autologin/";
    description = "PAM module to autologin with a saved password";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}

