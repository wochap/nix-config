{ config, pkgs, lib, ... }:

let
  cfg = config._custom.services.ssh;
  inherit (config._custom.globals) userName;
in {
  options._custom.services.ssh = { enable = lib.mkEnableOption { }; };

  config = lib.mkIf cfg.enable {
    services.openssh.enable = true;
    services.openssh.settings.PasswordAuthentication = false;
    services.openssh.settings.KbdInteractiveAuthentication = false;

    users.users.${userName}.openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCeEb8vEODQWvCOSRVF7gKIx/qkVst+3vjy0g2Y0f2IvEXT/1Rh+ndMgFAtM1zJAogKLVATxDtJq2zD+bT+cQqdJ2l26bR3iZ/1ZuykM7GKBpJJ2Z++XwxTebq32AZfVBBhJ5RMB1krJlqOaMmEHVeLWd/55iNeXqhbFYToDyYQ06LENA/bbib4qeuEHTCaRLrWqr7SWAL/sN2E6Q5OE52Lwh3KHaVm6hLM/p5G/bg42ZPNFsiGwwIijEmULEDH2bz03wT3LedYWY8YULQ0QDO6M6hAXsz4ZtNsoB+9XtuFC7HSryjZ7HW2s8bXau9z3EuQ1cqdIYQ7fsluj7QUkphur+uPU68kF2Rh81hMaEg3FbWbHW5LlvjFFFRU0yDV8RbJ5kUyuWEg0SA/zbjDE35XY3NET/rUxQKxDrLD0Wdn4dOyJ3bIqH2VgzmJKM2GE8iVNy9mV/krgi2dGFL98AXzdsWwFmIyQDa7PIYqXyflzzDmsR+PExQfQLY1B+iwaVJaJ5iNvuIiipTAkRPTd/rGHo92V9lpXSTu4eehzBfYdv/kbK7W4blvJ9AGXZcJxMLwWP206lgXA/wUnwSNB5l7Fa0ePeefwtVWpejYXrNlAEbYuXhYxHw+Z649WySQweuz0IrOc6j5/7g39TY63R3HQfA0HvaNypcA3mR8BJn78Q== w4ch4p@gmail.com"
    ];

    _custom.hm = {
      # NOTE: ssh agent managed by gnome-keyring

      home.packages = with pkgs; [ sshfs ];

      home.file = {
        ".ssh/config".source = ../../../../secrets/dotfiles/ssh-config;
      };
    };
  };
}
