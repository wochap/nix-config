{ fetchzip, lib, rustPlatform, installShellFiles, makeWrapper }:

rustPlatform.buildRustPackage rec {
  pname = "onagre";
  version = "1.0.0-alpha.0";

  # This release tarball includes source code for the tree-sitter grammars,
  # which is not ordinarily part of the repository.
  src = fetchzip {
    url = "https://github.com/oknozor/onagre/archive/refs/tags/${version}.tar.gz";
    sha256 = "sha256-En65OyAPNPPzDGdm2XTjbGG0NQFGBVzjjoyCbdnHFao=";
    stripRoot = false;
  };

  cargoSha256 = "sha256-oSS0L2Lg2JSRLYoF0+FVQzFUJtFuVKtU2MWYenmFC0s=";

  nativeBuildInputs = [ installShellFiles makeWrapper ];

  # postInstall = ''
  #   # not needed at runtime
  #   rm -r runtime/grammars/sources
  #   mkdir -p $out/lib
  #   cp -r runtime $out/lib
  #   installShellCompletion contrib/completion/hx.{bash,fish,zsh}
  #   mkdir -p $out/share/{applications,icons}
  #   cp contrib/Helix.desktop $out/share/applications
  #   cp contrib/helix.png $out/share/icons
  # '';
  # postFixup = ''
  #   wrapProgram $out/bin/hx --set HELIX_RUNTIME $out/lib/runtime
  # '';

  meta = with lib; {
    description = "Launcher";
    homepage = "https://github.com/oknozor/onagre";
    license = licenses.mit;
    # mainProgram = "hx";
    # maintainers = with maintainers; [];
  };
}
