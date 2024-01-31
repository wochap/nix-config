{ ... }:

{
  imports = [
    ./mixins/android
    ./mixins/docker
    ./mixins/flatpak
    ./mixins/interception-tools
    ./mixins/ipwebcam
    ./mixins/mbpfan
    ./mixins/mongodb
    ./mixins/ssh
    ./mixins/steam
    ./mixins/virt
    ./mixins/waydroid
    ./mixins/gnome-keyring.nix
    ./mixins/syncthing.nix
  ];
}
