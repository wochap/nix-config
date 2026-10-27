# Bugsink

[Bugsink](https://github.com/bugsink/bugsink) is a lightweight, self-hosted, Sentry-SDK compatible error tracking server.

## Features

- **Sentry SDK Compatible**: Point standard Sentry SDKs to your Bugsink DSN.
- **Podman / Docker (OCI-containers)**: Runs in an isolated container managed by systemd (`podman-bugsink.service` or `docker-bugsink.service`).
- **Zero-config SQLite by default**: Stored in `/var/lib/bugsink/db.sqlite3`, or configure external PostgreSQL via `DATABASE_URL`.
- **Automatic Secret Management**: Generates a persistent random 64-character `SECRET_KEY` in `/var/lib/bugsink/secret_key.env` if none is provided via `environmentFiles`.
- **Caddy & ACME Integration**: Automatically provisions a TLS certificate via Cloudflare DNS-01 and proxies over the tailnet.

## Quickstart

Add Bugsink to your host configuration (e.g. `hosts/gvps/default.nix`):

```nix
_custom.services.bugsink = {
  enable = true;
  tailnetDomain = "bugsink.gvps.geanmar.com";
  cloudflareTokenSecret.sopsFile = ../../secrets-sops/server.yaml;
};

services.headscale.settings.dns.extra_records = [
  {
    name = "bugsink.gvps.geanmar.com";
    type = "A";
    value = "100.64.0.4"; # Host's tailnet IP
  }
];
```

## Creating an Initial Superuser

You can create an admin user in one of two ways:

### 1. Via CLI interactive command

```sh
# For Podman (default backend):
sudo podman exec -it bugsink bugsink-manage createsuperuser

# For Docker:
sudo docker exec -it bugsink bugsink-manage createsuperuser
```

### 2. Via `CREATE_SUPERUSER` in an environment file

Add an environment file to `_custom.services.bugsink.environmentFiles`:

```env
CREATE_SUPERUSER=admin@example.com:your_secure_password
```

Bugsink will create this user on initial startup (if no users exist yet).

## Connecting Applications (Sentry SDK)

In any project using `@sentry/node`, `sentry-sdk` (Python), etc., set the DSN provided by Bugsink under your project settings:

```python
import sentry_sdk

sentry_sdk.init(
    dsn="https://<public_key>@bugsink.gvps.geanmar.com/<project_id>",
)
```

## Healthcheck & Monitoring

Bugsink exposes `/health/ready` and `/health/live`. You can monitor it in Gatus:

```nix
_custom.services.gatus.endpoints = [
  {
    name = "bugsink";
    group = "services";
    url = "https://bugsink.gvps.geanmar.com/health/ready";
    interval = "5m";
    conditions = [ "[STATUS] == 200" ];
  }
];
```

## Building Locally from Source

If you prefer building the OCI image locally instead of pulling the official image, enable `build`:

```nix
_custom.services.bugsink = {
  enable = true;
  build = {
    enable = true;
    source = inputs.bugsink; # Locked flake input
  };
};
```
