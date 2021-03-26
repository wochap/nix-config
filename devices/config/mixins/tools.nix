{ config, pkgs, lib, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      # base-devel
      bc # calculator cli
      dex # execute DesktopEntry files
      direnv # auto run nix-shell
      dos2unix # convert line breaks DOS - mac
      evtest # input debugging
      ffmpeg-full # music/video codecs?
      fzf # fuzzy search
      git
      glib # gio
      glxinfo # opengl utils
      gnumake # make
      inxi # check compositor running
      killall
      libqalculate # rofi-calc dependency
      libva-utils # verifying VA-API
      manpages
      mpc_cli
      mpd
      mpd_clientlib # mpd module
      notify-desktop # test notifications
      pciutils # lspci and others commands
      pulsemixer
      trash-cli # required by vscode
      unzip
      vdpauinfo # verifying VDPAU
      vim
      wget
      zip
    ];
  };
}
