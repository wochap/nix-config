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

      })
    ];

    environment = {
      systemPackages = with pkgs; [
        # TOOLS
        libinput
        libinput-gestures
        xorg.xev # get key actual name

        # TOOLS (wayland)
        wev # xev type
        wtype # xdotool

        # CLI TOOLS
        _custom.advcpmv # cp and mv with progress bar
        acpi
        acpitool
        cached-nix-shell # fast nix-shell scripts
        coreutils-full # a lot of commands
        devour # swallow
        dex # execute DesktopEntry files (xdg/autostart)
        dmidecode
        dnsutils # test dns
        efivar
        evtest # input debugging
        ffmpegthumbnailer
        glxinfo # opengl utils
        graphicsmagick
        heimdall # reset samsung ROM
        ifuse # mount ios
        inotify-tools # c module
        inxi # check compositor running
        libimobiledevice # mount ios
        libva-utils # verifying VA-API
        notify-desktop # test notifications
        pciutils # lspci and others commands
        pulsemixer
        slop # region selection
        usbutils # lsusb, for android development
        vdpauinfo # verifying VDPAU
        vulkan-tools
        wirelesstools
        xorg.xdpyinfo
        # base-devel
        # busybox # a lot of commands but with less options/features
        # mpc_cli
        # mpd
        # mpd_clientlib # mpd module
        # procps

        # 7w7
        nmap
        # metasploit
        # tightvnc

        # DE CLI
        hunspell # dictionary for document programs
        hunspellDicts.en-us
        pulseaudio
        systemd
        # pamixer # audio cli

        # APPS CLI
        unstable.ueberzugpp
        tty-clock

        # APPS GUI
        dmenu
        nyxt # browser
        skypeforlinux
        zoom-us
        # antimicroX
        # mysql-workbench
        # teamviewer

        # Electron apps
        bitwarden
        brave
        element-desktop-wayland
        figma-linux
        unstable.insomnia
        microsoft-edge
        notion-app-enhanced
        postman
        prevstable-chrome.google-chrome # HACK: fix https://github.com/NixOS/nixpkgs/issues/244742
        prevstable-chrome.netflix
        simplenote
        slack
        whatsapp-for-linux
      ];
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
