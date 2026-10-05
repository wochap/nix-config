{
  lib,
  rustPlatform,
  pinentry-gnome3,
  seahorse,
}:

rustPlatform.buildRustPackage {
  pname = "shell-auth";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.toml
      ./Cargo.lock
      ./src
    ];
  };

  cargoLock.lockFile = ./Cargo.lock;

  # stock tools used when the quickshell auth socket is unreachable
  env = {
    SHELL_AUTH_FALLBACK_PINENTRY = lib.getExe' pinentry-gnome3 "pinentry-gnome3";
    SHELL_AUTH_FALLBACK_ASKPASS = "${seahorse}/libexec/seahorse/ssh-askpass";
  };

  postInstall = ''
    ln -s shell-auth $out/bin/pinentry-shell
    ln -s shell-auth $out/bin/shell-askpass
  '';

  meta = {
    description = "Bridges pinentry, ssh askpass and the gnome-keyring prompter to the quickshell auth dialog";
    license = lib.licenses.mit;
    mainProgram = "shell-auth";
    platforms = lib.platforms.linux;
  };
}
