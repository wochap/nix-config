# Qwen3-ASR-1.7B for transcription and Qwen3-ForcedAligner-0.6B for word
# timestamps, both through the qwen-asr package.
{ config, lib, ... }:

let
  cfg = config._custom.services.ai.asr.qwen3;
in
{
  options._custom.services.ai.asr.qwen3 = {
    cuda.image = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/qwenllm/qwen3-asr@sha256:fb75b775f089e06e5a1aaebffd421e37505cc630d50c86d889d95ffa45a7e16a";
      description = ''
        Upstream Qwen3-ASR CUDA image. asr builds its CUDA image on top of
        it.
      '';
    };
  };

  config._custom.services.ai.asr.adapterRegistry.qwen3 = {
    module = ./adapter.py;
    image.cuda.tag = cfg.cuda.image;
    # vLLM and flash-attn are left out: the first is CUDA only, the second has
    # no gfx1030 kernels.
    pipPackages = [ "qwen-asr==0.0.6" ];
    models = {
      asr = {
        repo = "Qwen/Qwen3-ASR-1.7B";
        revision = "7278e1e70fe206f11671096ffdd38061171dd6e5";
        role = "transcriber";
      };
      aligner = {
        repo = "Qwen/Qwen3-ForcedAligner-0.6B";
        revision = "c7cbfc2048c462b0d63a45797104fc9db3ad62b7";
        role = "aligner";
      };
    };
  };
}
