{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.security.apparmor;

  policyOpts =
    {
      name,
      defaultPkg,
      defaultDir,
      defaultBinary,
    }:
    {
      enable = lib.mkEnableOption "AppArmor policy for ${name}";

      state = lib.mkOption {
        type = lib.types.enum [
          "disable"
          "complain"
          "enforce"
        ];
        default = "enforce";
        description = "Profile load mode. complain logs denials without blocking, useful for iterating on a profile.";
      };

      pkg = lib.mkOption {
        type = lib.types.package;
        default = defaultPkg;
        description = "Package to confine. When switching variants (e.g. discord-canary), also set dir and binary to match the variant's layout.";
      };

      dir = lib.mkOption {
        type = lib.types.str;
        default = defaultDir;
        description = "Directory containing the app binaries, relative to the package root.";
      };

      binary = lib.mkOption {
        type = lib.types.str;
        default = defaultBinary;
        description = "Main binary name inside dir.";
      };
    };
in
{
  options._custom.security.apparmor = {
    enable = lib.mkEnableOption {
      description = "AppArmor mandatory access control system";
    };

    policies = {
      brave = policyOpts {
        name = "brave";
        defaultPkg = pkgs.brave;
        defaultDir = "opt/brave.com/brave";
        defaultBinary = "brave";
      };

      discord = policyOpts {
        name = "discord";
        defaultPkg = pkgs.discord;
        defaultDir = "opt/Discord";
        defaultBinary = "Discord";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    security.apparmor = {
      enable = true;
      includes = {
        "abstractions/nix-gui" = builtins.readFile ./abstractions/nix-gui;
        "abstractions/nix-chromium" = builtins.readFile ./abstractions/nix-chromium;
      };
      policies = lib.mkMerge [
        (lib.mkIf cfg.policies.brave.enable {
          brave = {
            inherit (cfg.policies.brave) state;
            path = pkgs.replaceVars ./policies/brave {
              brave_dir = "${cfg.policies.brave.pkg}/${cfg.policies.brave.dir}";
              brave_exec = cfg.policies.brave.binary;
            };
          };
        })

        (lib.mkIf cfg.policies.discord.enable {
          discord = {
            inherit (cfg.policies.discord) state;
            # nixpkgs wraps the ELF in place: the real binary is a hidden
            # .<binary>-wrapped file exec'd by the wrapper script.
            path = pkgs.replaceVars ./policies/discord {
              discord_dir = "${cfg.policies.discord.pkg}/${cfg.policies.discord.dir}";
              discord_exec = ".${cfg.policies.discord.binary}-wrapped";
            };
          };
        })
      ];
    };
  };
}
