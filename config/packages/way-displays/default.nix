{ pkgs ? import <nixpkgs> { } }:

pkgs.stdenv.mkDerivation rec {
  pname = "way-displays";
  version = "1.3.0";

  src = pkgs.fetchFromGitHub {
    owner = "alex-courtis";
    repo = pname;
    rev = "${version}";
    sha256 = "sha256-QXJfhN5Ou37fkzhsic+fq50qeqsG6guJH+C/zokzsu8=";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp -f way-displays $out/bin
    chmod 755 $out/bin/way-displays
    mkdir -p $out/etc/way-displays
    cp -f cfg.yaml $out/etc/way-displays
    chmod 644 $out/etc/way-displays/cfg.yaml
  '';

  nativeBuildInputs = [ pkgs.libinput pkgs.libyamlcpp pkgs.gcc ];
  buildInputs = [ pkgs.wlroots pkgs.wayland pkgs.wayland-protocols ];

  meta = with pkgs.lib; {
    description = "Auto Manage Your Wayland Displays";
    homepage = "https://github.com/alex-courtis/way-displays";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
  };
}
