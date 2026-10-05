# Named model presets shared by the AI service modules: total context window
# and the largest completion the provider accepts. Token limits derive from
# these; VRAM is never an input because it says nothing about how much context
# a model gets. Import with `import ../model-presets.nix { inherit lib; }`.
{ lib }:

let
  presets = {
    # https://api-docs.deepseek.com/quick_start/pricing (1M context, 384K max output)
    deepseek-v4-flash = {
      contextTokens = 1048576;
      maxOutputTokens = 384000;
    };
    # https://ai.google.dev/gemma/docs/core (256K context);
    # https://openrouter.ai/google/gemma-4-31b-it (32768 max completion)
    gemma4-31b = {
      contextTokens = 262144;
      maxOutputTokens = 32768;
    };
    # https://openrouter.ai/qwen/qwen3.8-max-0902 (1M context, 131072 max output)
    qwen3-8-max = {
      contextTokens = 1000000;
      maxOutputTokens = 131072;
    };
    # ./ollama/models/gdesktop-qwen3.5:9b (num_ctx 32768); output capped at
    # a quarter of the window so prompts keep room for scraped context.
    qwen3-5-9b-local = {
      contextTokens = 32768;
      maxOutputTokens = 8192;
    };
    # Reproduce the limits hand-tuned on glegion before presets existed:
    # 131072 smart / 12000 fast / 16000 strategic with a 256K window.
    glegion-cloud-smart = {
      contextTokens = 262144;
      maxOutputTokens = 131072;
    };
    glegion-cloud-fast = {
      contextTokens = 262144;
      maxOutputTokens = 12000;
    };
    glegion-cloud-strategic = {
      contextTokens = 262144;
      maxOutputTokens = 16000;
    };
  };

  names = lib.concatStringsSep ", " (builtins.attrNames presets);
in
{
  inherit presets names;

  # A preset name, or the limits themselves.
  type = lib.types.either lib.types.str (
    lib.types.submodule {
      options = {
        contextTokens = lib.mkOption {
          type = lib.types.ints.positive;
          description = "Total context window (prompt plus completion) in tokens.";
        };
        maxOutputTokens = lib.mkOption {
          type = lib.types.ints.positive;
          description = "Largest completion the provider accepts, in tokens.";
        };
      };
    }
  );

  # `owner` names the module in the error for an unknown preset.
  resolve =
    owner: m:
    if builtins.isString m then
      presets.${m} or (throw "${owner}: unknown model preset \"${m}\"; known presets: ${names}")
    else
      m;

  # 131072 is the largest completion limit proven to work through OmniRoute.
  maxOutputCap = 131072;
}
