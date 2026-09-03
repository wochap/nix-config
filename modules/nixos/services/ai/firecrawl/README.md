# Firecrawl

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
