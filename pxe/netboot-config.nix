{ config, pkgs, ... }:

{
  # Inject your SSH key for passwordless remote access
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJslBuXKtnHU0vniaw1zedoRB9WhREYLT9kb/oDqo1a gean.marroquin@gmail.com"
  ];

  # You can easily add more temporary tools to the live environment here
  environment.systemPackages = with pkgs; [ git neovim htop ];

  # Add any additional temporary services or networking configs here
  # networking.hostName = "asus-live-env";
}
