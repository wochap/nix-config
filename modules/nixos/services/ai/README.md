## LLM

### Downloading model

- https://ollama.com/library
- https://huggingface.co/models

### Selecting models

Looking the following model name: `deepseek-coder:33b-instruct-q4_K_M`

- `33b` refers to the parameters, increasing the number generates better responses, but it also increases VRAM/RAM usage
- `q4` represents quantization bits, reducing the number decreases VRAM/RAM usage, but it also reduces the precision of responses
- `_K` suggests these versions might be quantized versions of the base models
- `_M` represent different sizes of the quantized models

### Downloading models

```sh
$ ollama pull <model>

# e.g.
$ ollama pull deepseek-coder:33b-instruct-q4_K_M
```

To download from huggingface:

```sh
$ huggingface-cli download <user/model> <file name>

# e.g.
$ huggingface-cli download TheBloke/WhiteRabbitNeo-13B-GGUF whiterabbitneo-13b.Q5_K_M.gguf
```

then create a Modelfile, `FROM` should point to path of the

### Usage of `Modelfile`s

You can download `Modelfile`s at https://openwebui.com/

```sh
$ ollama create <name> -f <location of the file>'

# e.g.
$ ollama create "deepseek-coder:33b-instruct-q4_K_M_glegion" -f ./models/glegion/Modelfile_deepseek-coder:33b-instruct-q4_K_M
```

### Testing models

```sh
$ curl http://localhost:11434/api/generate -d '{
  "model": "deepseek-coder:33b-instruct-q4_K_M",
  "prompt": "Why is the sky blue?",
  "options": {
    "num_gpu": 1,
    "num_thread": 8
  }
}
```

- `num_gpu` you need to test starting from 1 and increase until it uses almost all your available VRAM
- `num_thread` represents the number of physical cores

To calculate how fast the response is generated in tokens per second (token/s), divide eval_count / (eval_duration / 1000000000)

## OmniRoute chat helper

`omniroute-chat` sends an OpenAI-compatible chat request to the local OmniRoute instance. It is installed system-wide when `_custom.services.ai.enableOmniRoute` is enabled and is used by `clean-voice` and `article-summary`.

Configure OmniRoute before using the helper:

1. In **Dashboard → Endpoints**, create an endpoint API key and store its value in the SOPS secret `local-omniroute-secret-key`.
2. In **Dashboard → Combos**, create a persisted combo named `desktop-free`.
3. Select the **Priority** strategy for strict cloud-first ordering. **Fill First** can be used instead when each provider's available quota should be consumed before advancing.
4. Add the preferred free cloud provider models first, in desired order.
5. Add `glegion-qwen3.5:4b` through the Ollama provider as the final target.
6. In **Dashboard → Settings → Resilience**, enable connection cooldown, upstream retry hints, rate-limit auto-detection, and the provider circuit breaker. These allow quota, rate-limit, connection, and provider failures to advance through the combo.

By default, the helper uses:

- Base URL: `https://omniroute.wochap.local/v1`
- Model/combo: `desktop-free`
- API key file: `/run/secrets/local-omniroute-secret-key`

Override the combo used by an existing consumer:

```sh
$ OMNIROUTE_MODEL=another-combo clean-voice
```

Override the endpoint and API key, or invoke the helper directly:

```sh
$ OMNIROUTE_BASE_URL=http://127.0.1.1:20128/v1 \
    OMNIROUTE_API_KEY=... \
    omniroute-chat --model desktop-free < request.json
```

### Backing up and restoring OmniRoute

The NixOS module creates `/var/lib/omniroute`, but it does not recreate the
configuration stored there. OmniRoute keeps endpoint API keys, providers,
combos, resilience settings, and other dashboard state in
`/var/lib/omniroute/storage.sqlite`. A fresh installation therefore will not
contain the `desktop-free`, `firecrawl`, `research-fast`, or `research-smart`
combos used by these modules.

Back up the complete state directory while OmniRoute is stopped so the SQLite
database and its write-ahead log are captured consistently:

```console
$ sudo systemctl stop podman-omniroute.service
$ sudo tar --acls --xattrs -C /var/lib -cpf /path/to/backup/omniroute.tar omniroute
```

Treat the archive as a secret because the database contains provider and
endpoint credentials. Store it with the SOPS age private-key backup described
in the repository installation instructions.

After activating this NixOS configuration on the replacement machine, restore
the state before starting OmniRoute:

```console
$ sudo systemctl stop podman-omniroute.service
$ sudo tar --acls --xattrs -C /var/lib -xpf /path/to/backup/omniroute.tar
$ sudo chown -R 1000:1000 /var/lib/omniroute
$ sudo chmod 0700 /var/lib/omniroute
$ sudo systemctl start podman-omniroute.service
```

The `local-omniroute-secret-key` value in `secrets-sops/local.yaml` must match
the restored endpoint API key. Restore the SOPS age key first so NixOS can
render that secret, then verify `omniroute-chat` and each named combo.

### Article summaries

`article-page` is the reusable rendering layer. It turns any Markdown file into
a standalone HTML5 page and can optionally open it:

```sh
article-page --open notes.md
cat notes.md | article-page --output notes.html -
article-page --title "Weekly digest" --header header.html \
  --footer footer.html --output digest.html digest.md
```

Use `--head` for additions to the document `<head>`, or
`--no-default-style` when supplying all styling yourself. Enable it on its own
with `_custom.services.ai.enableArticlePage = true`; enabling article summaries
also installs it.

Enable the system-wide `article-summary` command with:

```nix
_custom.services.ai = {
  enable = true;
  enableOmniRoute = true;
  enableArticleSummary = true;
};
```

The command accepts an HTTP or HTTPS article URL, summarizes it through
OmniRoute, renders the result as HTML, and opens it with the configured XDG
browser. It can be invoked directly or integrated with an RSS reader.

## GPT Researcher

Enable the GPT Researcher Next.js UI and FastAPI backend with:

```nix
_custom.services.ai = {
  enable = true;
  enableGptResearcher = true;
  gptResearcherEnvironmentFile = config.sops.templates."gpt-researcher.env".path;
};
```

The UI is available at <https://gpt-researcher.wochap.local> and its API at
<https://gpt-researcher-api.wochap.local>. Both containers start lazily on the
first request. Reports, logs, and uploaded documents persist below
`/var/lib/gpt-researcher`.

Keep provider keys out of the Nix store by rendering the environment file with
SOPS. A basic OpenAI and Tavily configuration contains:

```dotenv
OPENAI_API_KEY=...
TAVILY_API_KEY=...
```

The environment file accepts GPT Researcher's other provider, model, retriever,
and scraper settings as well.

GPT Researcher keeps SearxNG as its search retriever and sends the pages it
finds to the local Firecrawl service for scraping.

## Firecrawl

Enable the self-hosted Firecrawl API with:

```nix
_custom.services.ai = {
  enable = true;
  enableOmniRoute = true;
  enableFirecrawl = true;
};
```

The API is available at <https://firecrawl.wochap.local> and starts lazily on
the first request. Firecrawl's Playwright, Redis, RabbitMQ, and NuQ PostgreSQL
services listen only on `127.0.1.1` and are not exposed through Nginx.

Test a Markdown scrape after activating the configuration:

```console
$ curl --fail-with-body https://firecrawl.wochap.local/v2/scrape \
    --header 'Content-Type: application/json' \
    --data '{"url":"https://example.com","formats":["markdown"]}'
```

Install the Firecrawl CLI and point it at the self-hosted API:

```console
$ npm install -g firecrawl-cli
$ firecrawl config --api-url https://firecrawl.wochap.local
```

The unversioned npm command installs the current CLI release. Pin a tested
`firecrawl-cli` version in this command if the CLI itself must be reproducible.

PostgreSQL, Redis, and RabbitMQ state persists in
`/var/lib/firecrawl/postgres`, `/var/lib/firecrawl/redis`, and
`/var/lib/firecrawl/rabbitmq`, respectively.

Firecrawl routes AI-backed extraction through OmniRoute. In the OmniRoute
dashboard, create a combo named `firecrawl` whose targets support the OpenAI
Responses API and structured output. The combo name can be changed with
`_custom.services.ai.firecrawlModel`. Keep the existing
`glegion-qwen3-embedding:4b` Ollama model available through OmniRoute for
embeddings; override it with `_custom.services.ai.firecrawlEmbeddingModel` only
when the replacement also supports the OpenAI embeddings endpoint.

## Whisper cpp

Downloading models for whisper-cpp

```sh
$ git clone https://github.com/ggerganov/whisper.cpp.git
$ cd whisper.cpp
$ sh ./models/download-ggml-model.sh large-v3
```

Running

```sh
$ whisper-cli -m /path-to/whisper.cpp/models/ggml-large-v3.bin -f audio.wav
```

[Available models](https://github.com/ggerganov/whisper.cpp/blob/master/models/README.md#available-models)

## Qwen3-ASR-1.7B

Enable on-demand transcription with the Transformers backend:

```nix
_custom.services.ai = {
  enable = true;
  enableNvidia = true;
  enableQwen3Asr = true;
};
```

Each command starts Qwen's official CUDA container, runs Transformers inference
on the NVIDIA GPU, and removes the container afterward. VRAM is therefore
released when transcription finishes; there is no persistent API server.

The pinned image is about 14 GB and the model download is about 4.7 GB. Rootless
Podman stores the image in the user's container storage and model files persist
in `~/.cache/qwen3-asr`.

Transcribe a local audio file:

```console
$ qwen3-asr-transcribe recording.wav
$ qwen3-asr-transcribe --language English recording.mp3
$ qwen3-asr-transcribe --language Spanish part-*.wav
```

For a video, the helper extracts mono 16 kHz audio with FFmpeg, transcribes it,
adds token timestamps with Qwen3-ForcedAligner-0.6B, and assigns speakers with
the local pyannote Community-1 pipeline. Before the first run, accept the model
conditions at <https://huggingface.co/pyannote/speaker-diarization-community-1>
and configure `personal-huggingface-local-read-token` in
`secrets-sops/personal.yaml`. An explicitly exported `HF_TOKEN` overrides the
configured secret:

```console
$ export HF_TOKEN=hf_...
$ qwen3-asr-video video.mp4
$ qwen3-asr-video --language English --num-speakers 2 video.mkv
$ qwen3-asr-video --language es --min-speakers 2 --max-speakers 5 video.mkv
```

The command writes `video.txt` and `video.json` by default. The text file has
one timestamped speaker turn per line, while the versioned JSON file retains
ASR chunks, detected languages, aligned tokens, exclusive diarization regions,
and merged turns. Use `--output` and `--json-output` to choose other paths.

The first invocation also builds a local inference image from Qwen's pinned
official image and installs the pinned pyannote runtime. Later runs reuse that
image and the model cache in `~/.cache/qwen3-asr`.

Long audio is transcribed in four-minute chunks to keep inference within an
8 GB GPU. Override the chunk duration if needed with
`QWEN3_ASR_CHUNK_SECONDS`; smaller values use less VRAM without changing the
model or audio quality:

```console
$ QWEN3_ASR_CHUNK_SECONDS=180 qwen3-asr-video long-video.mp4
```

The ASR, forced aligner, and diarization models are loaded sequentially rather
than simultaneously so the pipeline remains usable on an 8 GB RTX 4060.

The container receives only the temporary extracted audio read-only, the
inference script read-only, and the dedicated model cache. It does not receive
the containing video directory, the home directory, SSH/GPG keys, or a Podman
socket. No port is opened. After the image and all three models have been
downloaded once, set `QWEN3_ASR_OFFLINE=1` to disable container networking:

```console
$ QWEN3_ASR_OFFLINE=1 qwen3-asr-video video.mp4
```

## Supertonic text to speech

Enable the local Supertonic service and clipboard command:

```nix
_custom.services.ai = {
  enable = true;
  enableSupertonic = true;
};
```

After applying the NixOS configuration, download the Supertonic 3 model and
voice files into `~/.cache/supertonic3`:

```console
$ supertonic download
```

This setup step is optional. Starting `supertonic.service` with a missing model
downloads the same files automatically. The initial download is about 400 MB,
so the service can take longer than usual to become ready the first time.

Start Supertonic from the Quickshell Control Center before invoking
`supertonic-speak` or `supertonic-clipboard`. The commands report an error
instead of starting the service itself when the service is disabled.

### Usage

`supertonic-speak` accepts either a text string or a path to a text file.
`supertonic-clipboard` reads the regular clipboard by default and accepts
`primary` to read the middle-click selection. All options use strict
`--key=value` syntax and are shared by both commands:

```console
$ supertonic-speak "Text to speak"
$ supertonic-speak ./article.md          # Speak the contents of a file
$ supertonic-clipboard                   # Speak the regular clipboard (default)
$ supertonic-clipboard primary           # Speak the primary selection
$ supertonic-speak --pause               # Pause generation and playback
$ supertonic-speak --resume              # Resume generation and playback
$ supertonic-speak --toggle-pause        # Toggle pause; no-op when idle
$ supertonic-speak --stop                # Stop generation or playback
```

Literal text passed to `supertonic-speak` defaults to `raw`. For files,
`file --mime-type` detects HTML from its contents, including extensionless
files. Because Markdown is normally reported as plain text, `.md` and
`.markdown` files use Markdown; other files use raw text. An explicit
`--format` always overrides this inference.

### Input format

The default `auto` input mode prefers HTML when the copying application offers
an HTML clipboard MIME type. Otherwise, it treats the clipboard as
GitHub-flavored Markdown. Pandoc converts the input to readable plain text,
preserving useful paragraph and list structure while removing markup that
Supertonic does not understand.

Select the input format explicitly when automatic detection is not suitable:

```console
$ supertonic-speak code.txt --format=raw # Do not process the input text
$ supertonic-speak README.md --format=markdown
$ supertonic-speak page.html --format=html
$ supertonic-clipboard primary --format=markdown
```

Use `raw` for source code, literal markup, or Supertonic expression tags such
as `<laugh>`, `<breath>`, and `<sigh>`. Supertonic does not support HTML,
Markdown, or SSML directly; its expression tags represent nonverbal sounds,
not formatting such as bold or italics.

### Speed

Set any supported speed between `0.7` and `2.0` with `--speed`:

```console
$ supertonic-clipboard --speed=1.0       # Default
$ supertonic-speak article.md --speed=1.5
$ supertonic-clipboard primary --speed=1.8
```

Supertonic always synthesizes at `1.0` speed so changing playback speed does
not reduce model quality. The generated audio is played through `mpv`, which
applies pitch-corrected time stretching at the requested speed.

### Inference quality

Set the number of inference steps with `--steps`. Supertonic accepts integers
from `1` through `100`; this command defaults to `5`. Higher
values generally improve quality at the cost of generation time. Upstream
describes `5` through `12` as the typical quality range.

```console
$ supertonic-clipboard --steps=2         # Faster, lower quality
$ supertonic-clipboard --steps=5         # Default
$ supertonic-speak article.md --steps=8  # Upstream default quality
```

### Chunked playback

Application-level chunking is enabled by default. It starts playing the first
sentence-aware chunk while generating the next one. Disable it to submit the
entire selection in one request and wait for the complete response before
playback:

```console
$ supertonic-clipboard --chunking=on     # Default, lower perceived latency
$ supertonic-clipboard --chunking=off    # One request and one audio file
```

To inspect the exact text of every request sent to Supertonic, run playback in
the foreground with `--debug`:

```console
$ supertonic-clipboard --debug --chunking=on
```

The normalization mode is reported first. Each final chunk is then printed
immediately before its request.

### Voice

Supertonic 3 includes five male and five female built-in voices, named `M1`
through `M5` and `F1` through `F5`. `M1` is the default. Select another voice
with `--voice`:

```console
$ supertonic-clipboard --voice=F2
$ supertonic-clipboard primary --voice=M4 --speed=1.7
```

The same option accepts the name of an imported custom Supertonic voice.

### Toggle behavior

Invoking either command while speech is already generating or playing stops
the active operation. Long inputs are generated in sentence-aware chunks.
Playback begins after the first chunk, while the following chunk is generated
concurrently. Requests use the native Supertonic endpoint.

The Supertonic service remains running for faster subsequent requests. Stop it
from the Quickshell Control Center or manually when desired:

```console
$ systemctl --user stop supertonic.service
```

Inspect its status and logs with:

```console
$ systemctl --user status supertonic.service
$ journalctl --user --unit=supertonic.service --follow
```
