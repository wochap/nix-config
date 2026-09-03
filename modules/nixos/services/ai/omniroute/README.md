# OmniRoute

OmniRoute is the local OpenAI-compatible routing gateway that every other AI
service talks to. It provides combo-based model routing with failover across
cloud and local providers. The dashboard lives at
<https://omniroute.wochap.local>.

## Stack

| Component                                                                       | Role                                                   |
| ------------------------------------------------------------------------------- | ------------------------------------------------------ |
| [OmniRoute](https://github.com/diegosouzapw/omniroute) container (pinned image) | OpenAI-compatible gateway                              |
| Podman                                                                          | Container runtime (`podman-omniroute.service`)         |
| SQLite                                                                          | Dashboard state in `/var/lib/omniroute/storage.sqlite` |
| Nginx                                                                           | Reverse proxy on port 20128                            |
| SOPS                                                                            | Endpoint API key (`local-omniroute-secret-key`)        |
| `omniroute-chat` (Bash + curl/jq)                                               | System-wide chat helper                                |

## Setup

Configure OmniRoute before using it:

1. In **Dashboard → Endpoints**, create an endpoint API key and store its
   value in the SOPS secret `local-omniroute-secret-key`.
2. In **Dashboard → Combos**, create a persisted combo named `desktop-free`.
3. In **Dashboard → Settings → Resilience**, enable connection cooldown,
   upstream retry hints, rate-limit auto-detection, and the provider circuit
   breaker. These allow quota, rate-limit, connection, and provider failures
   to advance through the combo.

## Usage

`omniroute-chat` sends an OpenAI-compatible chat request to the local
instance. It is installed system-wide and is used by `clean-voice` and
`article-summary`. Defaults:

- Base URL: `https://omniroute.wochap.local/v1`
- Model/combo: `desktop-free`
- API key file: `/run/secrets/local-omniroute-secret-key`

Override the combo used by an existing consumer:

```sh
OMNIROUTE_MODEL=another-combo clean-voice
```

Override the endpoint and API key, or invoke the helper directly:

```sh
OMNIROUTE_BASE_URL=http://127.0.0.1:20128/v1 \
    OMNIROUTE_API_KEY=... \
    omniroute-chat --model desktop-free < request.json
```
