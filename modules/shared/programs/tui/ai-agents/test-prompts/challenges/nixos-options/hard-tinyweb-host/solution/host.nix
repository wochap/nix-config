{ pkgs, ... }:
{
  imports = [ ./tinyweb.nix ];

  networking.hostName = "web1";
  system.stateVersion = "26.05";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    tinyweb = {
      enable = true;
      sites = {
        docs = {
          port = 8081;
          root = "/srv/docs";
          openFirewall = true;
        };
        wiki = {
          port = 8082;
          root = "/srv/wiki";
          index = "Home.html";
        };
      };
    };
  };

  fonts = {
    enableDefaultPackages = true;
    packages = [ pkgs.noto-fonts ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.zsh.enable = true;
  users.users.alice = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.zsh;
  };
}
