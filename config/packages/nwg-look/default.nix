{ lib
, stdenv
, fetchgit
, substituteAll
, buildGoModule
, go
, glib
, pkg-config
, cairo
, gtk3
, xcur2png
, libX11
, zlib
}:

buildGoModule rec {
  pname = "nwg-look";
  version = "0.2.4";

  src = fetchgit {
    url = "https://github.com/nwg-piotr/nwg-look";
    rev = "f0f9f7278d7cbaa85862ad9a0ab42886c5938d61";
    hash = "sha256-wUI58qYkVYgES87HQ4octciDlOJ10oJldbUkFgxRUd4=";
  };

  vendorHash = "sha256-dev+TV6FITd29EfknwHDNI0gLao7gsC95Mg+3qQs93E=";

  patches = [ ./fix-paths.patch ];

  postPatch = ''
    sed -i 's|@out@|'"''${out}"'|g' main.go tools.go
  '';

  ldflags = [ "-s" "-w" ];

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    cairo
    xcur2png
    libX11.dev
    zlib
    gtk3
  ];

  CGO_ENABLED = 1;

  postInstall = ''
    mkdir -p $out/share
    mkdir -p $out/share/nwg-look/langs
    mkdir -p $out/share/applications
    mkdir -p $out/share/pixmaps
    cp stuff/main.glade $out/share/nwg-look/
    cp langs/* $out/share/nwg-look/langs
    cp stuff/nwg-look.desktop $out/share/applications
    cp stuff/nwg-look.svg $out/share/pixmaps
  '';

  meta = with lib; {
    homepage = "https://github.com/nwg-piotr/nwg-look";
    description = "Nwg-look is a GTK3 settings editor, designed to work properly in wlroots-based Wayland environment.";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ max-amb ];
    mainProgram = "nwg-look";
  };
}
