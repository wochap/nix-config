{ lib, stdenv, fetchFromGitHub, pkgs, fetchurl }:

stdenv.mkDerivation rec {
  pname = "scenefx";
  version = "2f9505ac96d97e32d6a243e87714b74ccdb70498";

  src = fetchFromGitHub {
    owner = "wlrfx";
    repo = pname;
    rev = version;
    hash = "sha256-4Z5KDDyjXlEaE+w9pojRebssrHnrXJzAkJ7vLZCLDV8=";
  };

  mesonFlags = [ "-Doptimization=2" ];

  patches = [
    (fetchurl {
      name = "install-headers-at-include-render";
      url =
        "https://github.com/wlrfx/scenefx/commit/640e92102b9043fdd840004b85be5aa7e1fddfa9.patch";
      sha256 = "sha256-q+OCZvpV6ppYfyT24y2WL9/iNEUNCTB230SI8HUt/0c=";
    })
  ];

  preConfigure = ''
    ls
    mkdir -p "$PWD/subprojects"
    cd "$PWD/subprojects"
    cp -R --no-preserve=mode,ownership ${pkgs.wlroots_0_17.src} wlroots
    chmod +x ./wlroots/backend/drm/gen_pnpids.sh
    cd ..
    ls
  '';

  depsBuildBuild = with pkgs;
    [
      # wlroots depsBuildBuild
      pkg-config
    ];

  nativeBuildInputs = with pkgs; [
    wayland

    # wlroots nativeBuildInputs
    meson
    ninja
    pkg-config
    wayland-scanner
    glslang
  ];

  buildInputs = with pkgs; [
    scdoc
    cmake

    # wlroots buildInputs
    libGL
    libcap
    libinput
    libpng
    libxkbcommon
    mesa
    pixman
    seatd
    vulkan-loader
    wayland
    wayland-protocols
    xorg.libX11
    xorg.xcbutilerrors
    xorg.xcbutilimage
    xorg.xcbutilrenderutil
    xorg.xcbutilwm
    xwayland
    ffmpeg
    hwdata
    libliftoff
    libdisplay-info
  ];

  meta = with lib; {
    description =
      "A drop-in replacement for the wlroots scene API that allows wayland compositors to render surfaces with eye-candy effects";
    homepage = "https://github.com/wlrfx/scenefx";
    license = licenses.mit;
    mainProgram = "scenefx";
    platforms = platforms.all;
  };
}

