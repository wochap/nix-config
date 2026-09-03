# GPT Researcher

Self-hosted [GPT Researcher](https://github.com/assafelovic/gpt-researcher):
an autonomous research agent with a Next.js UI at
<https://gpt-researcher.wochap.local> and a FastAPI backend at
<https://gpt-researcher-api.wochap.local>.

## Stack

| Component | Role |
|-----------|------|
| `gpt-researcher` local OCI image | FastAPI research backend |
| `gptr-nextjs` local OCI image | Next.js web UI |
| SearxNG | Search retriever |
| [Firecrawl](../firecrawl/README.md) | Page scraping |
| SOPS | Provider keys without touching the Nix store |

## Setup

```nix
_custom.services.ai = {
  enable = true;
  enableGptResearcher = true;
  gptResearcherEnvironmentFile = config.sops.templates."gpt-researcher.env".path;
};
```

Keep provider keys out of the Nix store by rendering the environment file
with SOPS. A basic OpenAI and Tavily configuration contains:

```dotenv
OPENAI_API_KEY=...
TAVILY_API_KEY=...
```

The environment file accepts GPT Researcher's other provider, model,
retriever, and scraper settings as well.

Both containers start lazily on the first request. Reports, logs, and
uploaded documents persist below `/var/lib/gpt-researcher`.

## Usage

Open the UI and submit a research query:

```sh
xdg-open https://gpt-researcher.wochap.local
```

The UI talks to the FastAPI backend at
<https://gpt-researcher-api.wochap.local>; both services start lazily on the
first request, so the first open can take a while.

GPT Researcher keeps SearxNG as its search retriever and sends the pages it
finds to the local Firecrawl service for scraping.
