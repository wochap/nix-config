{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.core-utils-linux;
in {
  options._custom.programs.core-utils-linux.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
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
      inotify-tools # C module, inotifywait
      inxi # log OS info
      keyutils # inspect kernel keyring
      libinput # input devices helper
      libinput-gestures # handle swipe events
      libva-utils # verifying VA-API
      ncdu # disk usage
      notify-desktop # send notifications
      pciutils # inspect/manipulate PCI devices, e.g. lspci
      pulseaudio
      pulsemixer # pulseaudio
      socat
      systemd
      vdpauinfo # verifying VDPAU
      vulkan-tools # verify vulkan
      wayvnc # vnc server
      wev # wayland like xev
      wirelesstools
      wtype # wayland like xdotool
      xorg.xdpyinfo
      xorg.xev # get pressed key name
      lazyjournal # journalctl tui

      ffmpegthumbnailer # video thumbnailer
      graphicsmagick # image editor
    ];

    programs.zsh.shellAliases.lj = ''run-without-kpadding lazyjournal "$@"'';
  };
}

