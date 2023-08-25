{ config, lib, pkgs, ... }:

let
  inherit (lib)
    all filterAttrs hasAttr isStorePath literalExpression optionalAttrs types;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf mkMerge;

  cfg = config._custom.programs.waybar;

  jsonFormat = pkgs.formats.json { };

  mkMargin = name:
    mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 10;
      description = "Margin value without unit.";
    };

  waybarBarConfig = with types;
    submodule {
      freeformType = jsonFormat.type;

      options = {
        layer = mkOption {
          type = nullOr (enum [ "top" "bottom" ]);
          default = null;
          description = ''
            Decide if the bar is displayed in front (`"top"`)
            of the windows or behind (`"bottom"`).
          '';
          example = "top";
        };

        output = mkOption {
          type = nullOr (either str (listOf str));
          default = null;
          example = literalExpression ''
            [ "DP-1" "!DP-2" "!DP-3" ]
          '';
          description = ''
            Specifies on which screen this bar will be displayed.
            Exclamation mark(!) can be used to exclude specific output.
          '';
        };

        position = mkOption {
          type = nullOr (enum [ "top" "bottom" "left" "right" ]);
          default = null;
          example = "right";
          description = "Bar position relative to the output.";
        };

        height = mkOption {
          type = nullOr ints.unsigned;
          default = null;
          example = 5;
          description =
            "Height to be used by the bar if possible. Leave blank for a dynamic value.";
        };

        width = mkOption {
          type = nullOr ints.unsigned;
          default = null;
          example = 5;
          description =
            "Width to be used by the bar if possible. Leave blank for a dynamic value.";
        };

        modules-left = mkOption {
          type = listOf str;
          default = [ ];
          description = "Modules that will be displayed on the left.";
          example = literalExpression ''
            [ "sway/workspaces" "sway/mode" "wlr/taskbar" ]
          '';
        };

        modules-center = mkOption {
          type = listOf str;
          default = [ ];
          description = "Modules that will be displayed in the center.";
          example = literalExpression ''
            [ "sway/window" ]
          '';
        };

        modules-right = mkOption {
          type = listOf str;
          default = [ ];
          description = "Modules that will be displayed on the right.";
          example = literalExpression ''
            [ "mpd" "custom/mymodule#with-css-id" "temperature" ]
          '';
        };

        modules = mkOption {
          type = jsonFormat.type;
          visible = false;
          default = null;
          description = "Modules configuration.";
          example = literalExpression ''
            {
              "sway/window" = {
                max-length = 50;
              };
              "clock" = {
                format-alt = "{:%a, %d. %b  %H:%M}";
              };
            }
          '';
        };

        margin = mkOption {
          type = nullOr str;
          default = null;
          description = "Margins value using the CSS format without units.";
          example = "20 5";
        };

        margin-left = mkMargin "left";
        margin-right = mkMargin "right";
        margin-bottom = mkMargin "bottom";
        margin-top = mkMargin "top";

        name = mkOption {
          type = nullOr str;
          default = null;
          description =
            "Optional name added as a CSS class, for styling multiple waybars.";
          example = "waybar-1";
        };

        gtk-layer-shell = mkOption {
          type = nullOr bool;
          default = null;
          example = false;
          description =
            "Option to disable the use of gtk-layer-shell for popups.";
        };
      };
    };
in {
  options._custom.programs.waybar = with lib.types; {
    enable = mkEnableOption "Waybar";

    settings = mkOption {
      type = either (listOf waybarBarConfig) (attrsOf waybarBarConfig);
      default = [ ];
      description = ''
        Configuration for Waybar, see <https://github.com/Alexays/Waybar/wiki/Configuration>
        for supported values.
      '';
      example = literalExpression ''
        {
          mainBar = {
            layer = "top";
            position = "top";
            height = 30;
            output = [
              "eDP-1"
              "HDMI-A-1"
            ];
            modules-left = [ "sway/workspaces" "sway/mode" "wlr/taskbar" ];
            modules-center = [ "sway/window" "custom/hello-from-waybar" ];
            modules-right = [ "mpd" "custom/mymodule#with-css-id" "temperature" ];

            "sway/workspaces" = {
              disable-scroll = true;
              all-outputs = true;
            };
            "custom/hello-from-waybar" = {
              format = "hello {}";
              max-length = 40;
              interval = "once";
              exec = pkgs.writeShellScript "hello-from-waybar" '''
                echo "from within waybar"
              ''';
            };
          };
        }
      '';
    };
  };

  config = let
    # Removes nulls because Waybar ignores them.
    # This is not recursive.
    removeTopLevelNulls = filterAttrs (_: v: v != null);

    # Makes the actual valid configuration Waybar accepts
    # (strips our custom settings before converting to JSON)
    makeConfiguration = configuration:
      let
        # The "modules" option is not valid in the JSON
        # as its descendants have to live at the top-level
        settingsWithoutModules = removeAttrs configuration [ "modules" ];
        settingsModules =
          optionalAttrs (configuration.modules != null) configuration.modules;
      in removeTopLevelNulls (settingsWithoutModules // settingsModules);

    # Allow using attrs for settings instead of a list in order to more easily override
    settings = if builtins.isAttrs cfg.settings then
      lib.attrValues cfg.settings
    else
      cfg.settings;

    # The clean list of configurations
    finalConfiguration = map makeConfiguration settings;

    configSource = jsonFormat.generate "waybar-config.json" finalConfiguration;

  in mkIf cfg.enable {
    xdg.configFile."waybar/config" = mkIf (settings != [ ]) {
      source = configSource;
      onChange = ''
        ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
      '';
    };
  };
}
