{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.services.ai;
  ocrCfg = cfg.ocr;
  registry = ocrCfg.adapterRegistry;

  # Unknown names are reported by the assertions below.
  enabledAdapters = lib.filterAttrs (name: _: lib.elem name ocrCfg.adapters) registry;
  # Bash declarations the ocr script reads its adapters from.
  declareAdapters =
    variable: attribute:
    "declare -A ${variable}=(${
      lib.concatMapStrings (
        name: " [${name}]=${lib.escapeShellArg enabledAdapters.${name}.${attribute}}"
      ) (lib.attrNames enabledAdapters)
    } )\n";
  ocrPrelude = ''
    ${declareAdapters "OCR_ADAPTER_COMMANDS" "command"}
    ${declareAdapters "OCR_ADAPTER_LABELS" "label"}
    OCR_DEFAULT_ADAPTER=${lib.escapeShellArg ocrCfg.defaultAdapter}
  '';

  ocr = pkgs.writeShellApplication {
    name = "ocr";
    text = ocrPrelude + builtins.readFile ./ocr.sh;
  };
in
{
  imports = [
    ./adapters/rapid
    ./adapters/glm
  ];

  options._custom.services.ai.ocr = {
    enable = lib.mkEnableOption { };

    adapterRegistry = lib.mkOption {
      internal = true;
      default = { };
      description = ''
        Screen OCR adapters registered by the modules under ./adapters.
        `ocr NAME` runs the adapter NAME.
      '';
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            label = lib.mkOption {
              type = lib.types.str;
              description = "Name shown in notifications.";
            };
            command = lib.mkOption {
              type = lib.types.str;
              description = ''
                Executable called as `command IMAGE`. It prints the text on
                stdout, exits nonzero on failure, and explains the failure on
                the last stderr line.
              '';
            };
            ollamaModels = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Models added to services.ollama.loadModels.";
            };
          };
        }
      );
    };

    adapters = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "rapid"
        "glm"
      ];
      description = ''
        Screen adapters `ocr` offers. Only these build their command and load
        their Ollama models.
      '';
    };

    defaultAdapter = lib.mkOption {
      type = lib.types.str;
      default = "rapid";
      description = "Adapter `ocr` runs without an argument; one of `adapters`.";
    };
  };

  config = lib.mkIf (cfg.enable && ocrCfg.enable) {
    assertions =
      map (name: {
        assertion = registry ? ${name};
        message = ''
          _custom.services.ai.ocr.adapters contains "${name}", which is not
          one of: ${lib.concatStringsSep ", " (lib.attrNames registry)}.
        '';
      }) ocrCfg.adapters
      ++ [
        {
          assertion = lib.elem ocrCfg.defaultAdapter ocrCfg.adapters;
          message = ''
            _custom.services.ai.ocr.defaultAdapter is "${ocrCfg.defaultAdapter}",
            which is not one of _custom.services.ai.ocr.adapters:
            ${lib.concatStringsSep ", " ocrCfg.adapters}.
          '';
        }
      ];

    environment.systemPackages = [ ocr ];

    services.ollama.loadModels = lib.mkAfter (
      lib.concatMap (adapter: adapter.ollamaModels) (lib.attrValues enabledAdapters)
    );
  };
}
