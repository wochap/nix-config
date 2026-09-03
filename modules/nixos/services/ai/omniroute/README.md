# OmniRoute

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

## Backing up and restoring OmniRoute

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
