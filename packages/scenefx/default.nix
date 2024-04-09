{ lib, stdenv, fetchFromGitHub, pkgs }:

stdenv.mkDerivation rec {
  pname = "scenefx";
  version = "de4ec10e1ff9347b5833f00f8615d760d9378c99";

  src = fetchFromGitHub {
    owner = "wlrfx";
    repo = pname;
    rev = version;
    hash = "sha256-4IWvkQCaPSB6o5XMK1aofP9IZWgFYhkqYbmYp/BB2+o=";
  };

  mesonFlags = [ "-Doptimization=2" ];

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

