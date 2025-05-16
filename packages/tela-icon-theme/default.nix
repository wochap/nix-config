{ lib, stdenvNoCC, fetchFromGitHub, gtk3, hicolor-icon-theme, jdupes
, allColorVariants ? false, colorVariants ? [ ] # default is standard
}:

let pname = "tela-icon-theme";
in lib.checkListOfEnum "${pname}: color variants" [
  "standard"
  "black"
  "blue"
  "brown"
  "green"
  "grey"
  "orange"
  "pink"
  "purple"
  "red"
  "yellow"
  "manjaro"
  "ubuntu"
  "dracula"
  "catppuccin_mocha"
  "nord"
] colorVariants

stdenvNoCC.mkDerivation rec {
  inherit pname;
  version = "397c57e4d3782aabe790766027e836976e208ee2";

  src = fetchFromGitHub {
    owner = "wochap";
    repo = pname;
    rev = version;
    sha256 = "sha256-mL2xqhy9bahqScC9+m2XUFQs5iUhMYHSw3c+0DG12qo=";
  };

  nativeBuildInputs = [ gtk3 jdupes ];

  propagatedBuildInputs = [ hicolor-icon-theme ];

  dontDropIconThemeCache = true;

  # These fixup steps are slow and unnecessary.
  dontPatchELF = true;
  dontRewriteSymlinks = true;

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
