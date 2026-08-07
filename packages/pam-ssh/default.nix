{
  lib,
  stdenv,
  fetchurl,
  pam,
  openssl,
  openssh,
}:

stdenv.mkDerivation rec {
  pname = "pam_ssh";
  version = "2.3";

  src = fetchurl {
    url = "mirror://sourceforge/pam-ssh/pam_ssh/${version}/pam_ssh-${version}.tar.xz";
    sha512 = "sha512-493PhR/9j2+4MeLe5yacG4koOuL49qo0h797G8cdJqyby9KgHFpnqYO5gLu1FR6ZFAKUD0dSdBKG0FeEPIF4lQ==";
  };

  patches = [
    (fetchurl {
      url = "https://709312.bugs.gentoo.org/attachment.cgi?id=634046";
      sha512 = "sha512-BkA2+Z+IwULVhbCCW/bCDRDUD7HKBq0JvlGAT9Scst/L7nYzqa5SN+VLDJqiCy72h/6i+og+MCKzUseMJfxNPw==";
      name = "fix-common.patch";
    })
  ];

  buildInputs = [
    pam
    openssl
    openssh
  ];

  env.NIX_CFLAGS_COMPILE = "-std=gnu89 -I${pam}/include/security";

  configureFlags = [
    "--with-pam-dir=${placeholder "out"}/lib/security"
  ];

  meta = with lib; {
    description = "PAM module providing single sign-on behavior for SSH";
    homepage = "http://pam-ssh.sourceforge.net/";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
