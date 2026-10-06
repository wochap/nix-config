# Firecrawl

Self-hosted [Firecrawl](https://firecrawl.dev) scraping and content-extraction
API, exposed at <https://firecrawl.wochap.local>.

## Stack

| Component | Role |
|-----------|------|
| Firecrawl API + worker containers | Scrape/crawl/extract endpoints (pinned images) |
| Playwright service container | Headless page rendering |
| Redis 7 container | Queue/cache |
| RabbitMQ container | Job broker |
| NuQ PostgreSQL container | Persistence |
| OmniRoute | AI-backed extraction and embeddings |
| Nginx | Reverse proxy (internal services not exposed) |

All backing services listen only on `127.0.0.1` and are not exposed through
Nginx; only the API itself is proxied.

## Setup

Configure OmniRoute before first use:

1. In the OmniRoute dashboard, create a combo named `firecrawl` whose targets
   support the OpenAI Responses API and structured output. Rename it with
   `_custom.services.ai.firecrawlModel` if desired.
2. Keep the Ollama model named by `_custom.services.ai.ollamaEmbeddingModel`
   (default `glegion-qwen3-embedding:4b`) available through OmniRoute for
   embeddings; override it per service with
   `_custom.services.ai.firecrawlEmbeddingModel` only when the replacement
   also supports the OpenAI embeddings endpoint.
3. Optionally set `firecrawlEnvironmentFile` for additional overrides and
   secrets.

The API starts lazily on the first request. PostgreSQL, Redis, and RabbitMQ
state persists in `/var/lib/firecrawl/postgres`, `/var/lib/firecrawl/redis`,
and `/var/lib/firecrawl/rabbitmq`, respectively.

## Usage

Test a Markdown scrape after activating the configuration:

```sh
curl --fail-with-body https://firecrawl.wochap.local/v2/scrape \
    --header 'Content-Type: application/json' \
    --data '{"url":"https://example.com","formats":["markdown"]}'
```

Install the Firecrawl CLI and point it at the self-hosted API:

```sh
npm install -g firecrawl-cli
firecrawl config --api-url https://firecrawl.wochap.local
```

The unversioned npm command installs the current CLI release. Pin a tested
`firecrawl-cli` version in this command if the CLI itself must be
reproducible.

## Upgrade

Images are pinned by tag and digest in `default.nix`, as options under
`_custom.services.ai`:

| Option | Image |
|--------|-------|
| `firecrawlImage` | API and worker (`ghcr.io/firecrawl/firecrawl`) |
| `firecrawlPlaywrightImage` | Playwright service |
| `firecrawlPostgresImage` | NuQ PostgreSQL |
| `firecrawlRedisImage` | Redis |
| `firecrawlRabbitmqImage` | RabbitMQ |

Firecrawl images use the `latest` tag, so the digest is what changes.

1. Read the release notes at <https://github.com/firecrawl/firecrawl/releases>.
2. Get the current digest of the tag:

   ```sh
   skopeo inspect --format '{{.Digest}}' docker://ghcr.io/firecrawl/firecrawl:latest
   ```

3. Replace the `sha256:` digest (and the tag, if it is not `latest`) in the
   option default. Upgrade the API, Playwright and NuQ PostgreSQL images
   together, because they are built from the same release.
4. Rebuild and switch. The API starts lazily, so the first request after the
   switch pulls the new images.
5. Run the scrape test from [Usage](#usage) and check the logs:

   ```sh
   sudo journalctl -u podman-firecrawl-api -e
   ```

Do not change the major version of Redis, RabbitMQ or PostgreSQL without a
migration plan: their data persists in `/var/lib/firecrawl/`. To roll back,
restore the previous digest and rebuild.
