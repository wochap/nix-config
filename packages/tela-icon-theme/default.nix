{ lib, stdenvNoCC, fetchFromGitHub, adwaita-icon-theme, libsForQt5, gtk3, hicolor-icon-theme
, jdupes, gitUpdater, allColorVariants ? false
, colorVariants ? [ ] # default is standard
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
  version = "6946b39b13fe5c1b8eb4111a8d4a2f7a5f57b060";

  src = fetchFromGitHub {
    owner = "wochap";
    repo = pname;
    rev = version;
    sha256 = "sha256-qsNN6tF+IHXxYDsoCU4qRCHnRPNCyrAZ+Nb9NHY47lQ=";
  };

  nativeBuildInputs = [ gtk3 jdupes ];

  propagatedBuildInputs =
    [ adwaita-icon-theme libsForQt5.breeze-icons hicolor-icon-theme ];

  dontDropIconThemeCache = true;

  # These fixup steps are slow and unnecessary for this package.
  # Package may install almost 400 000 small files.
  dontPatchELF = true;
  dontRewriteSymlinks = true;

  postPatch = ''
    patchShebangs install.sh
  '';

  installPhase = ''
    runHook preInstall

    ./install.sh -d $out/share/icons \
      ${if allColorVariants then "-a" else builtins.toString colorVariants}

    jdupes --quiet --link-soft --recurse $out/share

    runHook postInstall
  '';

  passthru.updateScript = gitUpdater { };

  meta = with lib; {
    description = "Flat and colorful personality icon theme";
    homepage = "https://github.com/wochap/Tela-icon-theme";
    license = licenses.gpl3Only;
    platforms =
      platforms.linux; # darwin use case-insensitive filesystems that cause hash mismatches
    maintainers = with maintainers; [ ];
  };
}
