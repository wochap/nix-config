{ config, pkgs, ... }:

{
  # Inject your SSH key for passwordless remote access
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJslBuXKtnHU0vniaw1zedoRB9WhREYLT9kb/oDqo1a gean.marroquin@gmail.com"
  ];

  # You can easily add more temporary tools to the live environment here
  environment.systemPackages = with pkgs; [ git ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
