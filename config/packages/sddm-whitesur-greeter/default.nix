{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "sddm-whitesur-greeter";
  version = "1.2";
  dontBuild = true;
  installPhase = ''
    mkdir -p $out/share/sddm/themes
    cp -aR $src/sddm/WhiteSur $out/share/sddm/themes/whitesur
  '';
  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "WhiteSur-kde";
    rev = "04b3436b58814b63614841c8bbe61b5bcc6cd789";
    sha256 = "1wyxdk1d0ahhxddqk5w7vfbg4ly817qvibzfd6p2534r3p0a54d5";
  };
}
