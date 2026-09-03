# GPT Researcher

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
