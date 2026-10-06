{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitLab,
  unzip,
  libfprint,
}:

# libfprint with the FPC match-on-host driver (10a5:9800, Legion Slim 5 14APH8
# and ThinkPad E14/E16), upstream lists the sensor as unsupported
# source: https://gitlab.freedesktop.org/libfprint/libfprint/-/merge_requests/396
# source: https://aur.archlinux.org/packages/libfprint-fpcmoh-git
let
  # proprietary matching algorithm shipped by Lenovo, only needs libc
  libfpcbep = stdenv.mkDerivation {
    pname = "libfpcbep";
    version = "27.26.23.39";

    src = fetchurl {
      url = "https://download.lenovo.com/pccbbs/mobiles/r1slm01w.zip";
      sha256 = "c7290f2a70d48f7bdd09bee985534d3511ec00d091887b07f81cf1e08f74c145";
    };

    nativeBuildInputs = [ unzip ];
    sourceRoot = ".";
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 FPC_driver_linux_27.26.23.39/install_fpc/libfpcbep.so $out/lib/libfpcbep.so
      install -Dm644 FPC_driver_linux_libfprint/install_libfprint/lib/udev/rules.d/60-libfprint-2-device-fpc.rules \
        $out/lib/udev/rules.d/60-libfprint-2-device-fpc.rules
      runHook postInstall
    '';

    meta.license = lib.licenses.unfree;
  };
in
libfprint.overrideAttrs (old: {
  pname = "libfprint-fpcmoh";
  # fpcmoh.patch is rebased on this tag
  version = "1.94.10";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "libfprint";
    repo = "libfprint";
    rev = "v1.94.10";
    hash = "sha256-aNBUIKY3PP5A07UNg3N0qq+2cwb6Fk67oKQcXgr2G/4=";
  };

  patches = (old.patches or [ ]) ++ [ ./fpcmoh.patch ];

  # libfpcbep.so has no SONAME, linking by full path keeps it in NEEDED
  postPatch = (old.postPatch or "") + ''
    substituteInPlace meson.build \
      --replace-fail "find_library('fpcbep', required: true)" \
        "find_library('fpcbep', required: true, dirs: '${libfpcbep}/lib')"
  '';

  postInstall = (old.postInstall or "") + ''
    install -Dm644 ${libfpcbep}/lib/udev/rules.d/60-libfprint-2-device-fpc.rules \
      $out/lib/udev/rules.d/60-libfprint-2-device-fpc.rules
  '';

  # meson runs tests/*.py at configure time even when they are skipped,
  # upstream only provides that python through the install checks
  nativeBuildInputs = old.nativeBuildInputs ++ (old.nativeInstallCheckInputs or [ ]);

  # upstream tests know nothing about the out of tree driver
  doInstallCheck = false;

  passthru = (old.passthru or { }) // {
    inherit libfpcbep;
  };
})
