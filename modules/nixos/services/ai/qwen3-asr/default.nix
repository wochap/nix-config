{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  inherit (config._custom.globals) userName;
  asr-revision = "7278e1e70fe206f11671096ffdd38061171dd6e5";
  aligner-revision = "c7cbfc2048c462b0d63a45797104fc9db3ad62b7";
  diarizer-revision = "3533c8cf8e369892e6b79ff1bf80f7b0286a54ee";
  transformers = pkgs.writeText "qwen3-asr-transformers.py" (
    builtins.readFile ./qwen3-asr-transformers.py
  );
  pipeline = pkgs.writeText "qwen3-asr-pipeline.py" (builtins.readFile ./qwen3-asr-pipeline.py);
  container-file = ./qwen3-asr-diarization.Containerfile;
  container-version = builtins.substring 0 16 (
    builtins.hashString "sha256" (builtins.readFile container-file)
  );
  container-context = pkgs.runCommand "qwen3-asr-diarization-context" { } ''
    mkdir -p "$out"
    cp ${container-file} "$out/Containerfile"
  '';
  qwen3-asr-transcribe = pkgs.writeShellApplication {
    name = "qwen3-asr-transcribe";
    runtimeEnv = {
      # TODO: Make the inference image configurable and provide an AMD/ROCm variant;
      # this upstream image is CUDA/NVIDIA-specific.
      QWEN3_ASR_IMAGE = "docker.io/qwenllm/qwen3-asr@sha256:fb75b775f089e06e5a1aaebffd421e37505cc630d50c86d889d95ffa45a7e16a";
      QWEN3_ASR_ASR_REVISION = asr-revision;
      QWEN3_ASR_SCRIPT = transformers;
    };
    text = builtins.readFile ./qwen3-asr-transcribe.sh;
  };
  qwen3-asr-video = pkgs.writeShellApplication {
    name = "qwen3-asr-video";
    runtimeEnv = {
      QWEN3_ASR_DIARIZATION_CONTEXT = container-context;
      QWEN3_ASR_DIARIZATION_IMAGE = "localhost/qwen3-asr-diarization:${container-version}";
      QWEN3_ASR_ASR_REVISION = asr-revision;
      QWEN3_ASR_ALIGNER_REVISION = aligner-revision;
      QWEN3_ASR_DIARIZER_REVISION = diarizer-revision;
      QWEN3_ASR_HF_TOKEN_FILE = config.sops.secrets.personal-huggingface-local-read-token.path;
      QWEN3_ASR_PIPELINE_SCRIPT = pipeline;
    };
    text = builtins.readFile ./qwen3-asr-video.sh;
  };
in
{
  options._custom.services.ai.enableQwen3Asr = lib.mkEnableOption { };

  config = lib.mkIf (cfg.enable && cfg.enableQwen3Asr) {
    sops.secrets.personal-huggingface-local-read-token = {
      sopsFile = ../../../../../secrets-sops/personal.yaml;
      owner = userName;
    };

    environment.systemPackages = [
      qwen3-asr-transcribe
      qwen3-asr-video
    ];
  };
}
