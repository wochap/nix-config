{ lib, pkgs ? import <nixpkgs> {}, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "ptsh";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    repo = "ptSh";
    owner = "jszczerbinsky";
    rev = "737685cf64dcd00572d3997a6f2b514219156288";
    sha256 = "1mzajnv455kdsvlb2s2ib382as1l00q505499qylxr3zna1m4ch1";
  };

  dontBuild = true;
  sourceRoot = ".";

  installPhase = ''
   	mkdir -p $out/share/ptSh
    mkdir -p $out/bin
    cp ./source/src/set_aliases.sh $out/bin/ptSh_set_aliases
    cp ./source/src/ptLs.sh $out/bin/ptls
    cp ./source/src/ptPwd.sh $out/bin/ptpwd
    cp ./source/src/ptMkdir.sh $out/bin/ptmkdir
    cp ./source/src/ptTouch.sh $out/bin/pttouch
    cp ./source/src/ptCp.sh $out/bin/ptcp
    cp ./source/src/ptRm.sh $out/bin/ptrm
    cp ./source/src/ptsh.sh $out/bin/ptsh
  '';

  meta = with pkgs.lib; {
    description = "ptSh";
    homepage = "https://github.com/jszczerbinsky/ptSh";
  };
}
