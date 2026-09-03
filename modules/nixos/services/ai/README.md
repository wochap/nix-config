# AI Services

This directory contains NixOS modules for local and self-hosted AI services.

## Services

| Service | Description |
|---------|-------------|
| [omniroute](./omniroute/README.md) | OpenAI-compatible routing gateway with combo-based failover |
| [firecrawl](./firecrawl/README.md) | Self-hosted web scraping and content extraction API |
| [gpt-researcher](./gpt-researcher/README.md) | Autonomous research agent with Next.js UI |
| [article-page](./article-page/README.md) | Markdown-to-HTML5 rendering helper |
| [article-summary](./article-summary/README.md) | URL → OmniRoute summary → HTML page |
| [article-scrape](./article-scrape/) | Rendered page fetching and text extraction |
| [qwen3-asr](./qwen3-asr/README.md) | GPU-accelerated speech recognition and speaker diarization |
| [supertonic](./supertonic/README.md) | Local text-to-speech with clipboard integration |
| [ocr](./ocr/README.md) | Screen region OCR (RapidOCR / GLM-OCR) |
| [models](./models/README.md) | LLM model management, selection, and Whisper |

## Quick start

Enable the top-level AI bundle and the services you need:

```nix
_custom.services.ai = {
  enable = true;
  enableOmniRoute = true;
  enableFirecrawl = true;
  enableGptResearcher = true;
  enableArticleSummary = true;
  enableQwen3Asr = true;
  enableSupertonic = true;
};
```

Each sub-directory README documents its own prerequisites, configuration, and
usage.
