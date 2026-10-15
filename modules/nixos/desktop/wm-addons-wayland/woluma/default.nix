{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.desktop.woluma;
  inherit (config._custom.globals) userName systemdTarget;
  tomlFormat = pkgs.formats.toml { };
in
{
  # backlight udev rules, video/i2c groups
  imports = [ inputs.woluma.nixosModules.default ];

  options._custom.desktop.woluma = {
    enable = lib.mkEnableOption { };
    enableSystemd = lib.mkEnableOption { };
    enableDdc = lib.mkEnableOption { };
    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          general.settle = "2s";
          outputs.eDP-1 = {
            backlight = "amdgpu_bl1";
            rules = [
              { name = "bright"; when.luma = ">= 70"; brightness = 40; }
              { name = "default"; brightness = 70; }
            ];
          };
        }
      '';
    };
  };

  config = lib.mkMerge [
    # set unconditionally: backlight.enable defaults to true in the upstream module
    { services.woluma.backlight.enable = cfg.enable; }

    (lib.mkIf cfg.enable {
      services.woluma = {
        users = [ userName ];
        ddc.enable = cfg.enableDdc;
      };

      _custom.hm = {
        imports = [ inputs.woluma.homeManagerModules.default ];

        services.woluma = {
          enable = true;
          inherit (cfg) settings;
        inherit systemdTarget;
          extraPackages = with pkgs; [ libnotify ];
        };

        # the upstream module always defines the service, only start it on demand
        systemd.user.services.woluma.Install.WantedBy = lib.mkIf (!cfg.enableSystemd) (lib.mkForce [ ]);
      };
    })
  ];
}
