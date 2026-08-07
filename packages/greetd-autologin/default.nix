{
  lib,
  buildGoModule,
}:

buildGoModule {
  pname = "greetd-autologin";
  version = "1.0.0";

  src = ./.;

  vendorHash = null;

  meta = with lib; {
    description = "A fast greetd autologin greeter written in Go";
    mainProgram = "greetd-autologin";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
