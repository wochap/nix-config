{
  lib,
  buildGoModule,
}:

buildGoModule {
  pname = "run-desktop";
  version = "1.0.0";

  src = ./.;

  vendorHash = null;

  meta = with lib; {
    description = "A fast session launcher written in Go";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
