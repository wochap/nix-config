{ lib, stdenvNoCC, fetchFromGitHub, gtk3, hicolor-icon-theme, jdupes
, allColorVariants ? false, colorVariants ? [ ] # default is standard
}:

let pname = "tela-icon-theme";
in lib.checkListOfEnum "${pname}: color variants" [
  "standard"
  "catppuccin_mocha_sky"
  "catppuccin_mocha_blue"
  "catppuccin_mocha_lavender"
] colorVariants

stdenvNoCC.mkDerivation rec {
  inherit pname;
  version = "46c6321b1df87a3d828ccb19ed097c83ed3035df";

  src = fetchFromGitHub {
    owner = "wochap";
    repo = pname;
    rev = version;
    sha256 = "sha256-vV3YqXmnAh6yS4IIza6ABDSJ+SyDYnLYC+NesJsxzJQ=";
  };

  nativeBuildInputs = [ gtk3 jdupes ];

  propagatedBuildInputs = [ hicolor-icon-theme ];

  dontDropIconThemeCache = true;

  # These fixup steps are slow and unnecessary.
  dontPatchELF = true;
  dontRewriteSymlinks = true;
  dontCheckForBrokenSymlinks = true;
  dontPatchShebangs = true;

  installPhase = ''
    runHook preInstall

    patchShebangs install.sh
    mkdir -p $out/share/icons
    ./install.sh -d $out/share/icons \
      ${if allColorVariants then "-a" else builtins.toString colorVariants}
    jdupes -l -r $out/share/icons

    runHook postInstall
  '';

  meta = with lib; {
    description = "Flat and colorful personality icon theme";
    homepage = "https://github.com/wochap/Tela-icon-theme";
    license = licenses.gpl3Only;
    # darwin systems use case-insensitive filesystems that cause hash mismatches
    platforms = subtractLists platforms.darwin platforms.unix;
    maintainers = with maintainers; [ ];
  };
}
