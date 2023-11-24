{ config, pkgs, lib, inputs, ... }:

let userName = config._userName;
in {
  config = {
    nixpkgs.overlays = [
      (final: prev: {
        insomnia = prev.runCommandNoCC "insomnia" {
          buildInputs = with pkgs; [ makeWrapper ];
        } ''
          makeWrapper ${prev.insomnia}/bin/insomnia $out/bin/insomnia \
          --add-flags "--enable-features=UseOzonePlatform" \
          --add-flags "--ozone-platform=wayland"

          ln -sf ${prev.insomnia}/share $out/share
        '';

        microsoft-edge = prev.runCommandNoCC "microsoft-edge" {
          buildInputs = with pkgs; [ makeWrapper ];
        } ''
          makeWrapper ${prev.microsoft-edge}/bin/microsoft-edge $out/bin/microsoft-edge \
          --add-flags "--enable-features=WebRTCPipeWireCapturer" \
          --add-flags "--enable-features=UseOzonePlatform" \
          --add-flags "--ozone-platform=wayland"

          ln -sf ${prev.microsoft-edge}/share $out/share
        '';

        heimdall = prev.heimdall.overrideAttrs (_: {
          src = prev.fetchFromSourcehut {
            owner = "~grimler";
            repo = "Heimdall";
            rev = "02b577ec774f2ce66bcb4cf96cf15d8d3d4c7720";
            sha256 = "sha256-tcAE83CEHXCvHSn/S9pWu6pUiqGmukMifEadqPDTkQ0=";
          };
        });
      })
    ];

    environment = {
      systemPackages = with pkgs; [
        # OHERS
        heimdall # reset samsung ROM
        ifuse # mount ios
        inotify-tools # c module
        libimobiledevice # mount ios

        # 7w7
        nmap
        # metasploit
        # tightvnc

        # CLI TOOLS (xorg)
        devour # window swallower
        libinput-gestures # handle swipe events
        slop # region selection
        xorg.xev # get pressed key name

        # CLI TOOLS (wayland)
        wev # like xev
        wtype # like xdotool

        # CLI TOOLS
        _custom.advcpmv # cp/mv with progress bar
        acpi # log battery/temp info
        acpitool # like acpi + control hw
        cached-nix-shell # fast nix-shell scripts
        clinfo # print info about OpenCL
        coreutils-full # GNU utils commands
        dex # execute DesktopEntry files (xdg/autostart)
        dmidecode # log hw info
        dnsutils # test dns
        efivar # manipulate efi vars
        evtest # input debugging
        glxinfo # opengl utils
        hunspell # dictionary for document programs
        hunspellDicts.en-us
        inxi # log OS info
        libinput # input devices helper
        libva-utils # verifying VA-API
        notify-desktop # send notifications
        pciutils # inspect/manipulate PCI devices, e.g. lspci
        pulseaudio
        systemd
        usbutils # lsusb, for android development
        vdpauinfo # verifying VDPAU
        vulkan-tools # verify vulkan
        wirelesstools
        xorg.xdpyinfo

        # CLI APPS
        ffmpegthumbnailer # video thumbnailer
        graphicsmagick # image editor

        # TUI APPS
        ncdu # disk usage
        pulsemixer # pulseaudio
        tty-clock # clock
        unstable.ueberzugpp # images in terminal

        # GUI APPS
        dmenu # menu
        nyxt # browser
        skypeforlinux
        zoom-us
        # antimicroX # map kb/mouse to gamepad
        # mysql-workbench
        # teamviewer

        # ELECTRON APPS
        bitwarden
        brave
        element-desktop-wayland
        figma-linux
        microsoft-edge
        notion-app-enhanced
        postman
        prevstable-chrome.google-chrome # HACK: fix https://github.com/NixOS/nixpkgs/issues/244742
        prevstable-chrome.netflix
        simplenote
        slack
        unstable.insomnia
        whatsapp-for-linux
      ];

      shellAliases = { ttc = ''tty-clock -c -C 2 -r -f "%A, %B %d"''; };
    };

    home-manager.users.${userName} = {
      xdg.desktopEntries = {
        insomnia = {
          name = "Insomnia";
          exec = "insomnia %U";
        };
        microsoft-edge = {
          name = "Microsoft Edge";
          exec = "microsoft-edge %U";
        };
      };
    };
  };
}
