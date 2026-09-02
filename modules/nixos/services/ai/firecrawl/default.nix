{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.ai;
  inherit (pkgs._custom) wochap-ssc;
  proxy = config._custom.services.web-proxies.firecrawl;

  ports = {
    playwright = 20902;
    redis = 20903;
    rabbitmq = 20904;
    postgres = 20905;
    extractWorker = 20906;
    worker = 20907;
    nuqWorker = 20908;
    nuqWorkerStart = 20910;
    nuqPrefetchWorker = 20915;
    nuqReconcilerWorker = 20916;
    rabbitmqManagement = 20917;
    rabbitmqPrometheus = 20918;
    rabbitmqDistribution = 20919;
    rabbitmqEpmd = 20920;
  };

  address = wochap-ssc.meta.address;
  postgresUrl = "postgres://firecrawl:firecrawl@${address}:${toString ports.postgres}/postgres";

  rabbitmqConfig = pkgs.writeText "firecrawl-rabbitmq.conf" ''
    listeners.tcp.default = ${address}:${toString ports.rabbitmq}
    management.tcp.ip = ${address}
    management.tcp.port = ${toString ports.rabbitmqManagement}
    prometheus.tcp.ip = ${address}
    prometheus.tcp.port = ${toString ports.rabbitmqPrometheus}
    distribution.listener.interface = ${address}
    distribution.listener.port_range.min = ${toString ports.rabbitmqDistribution}
    distribution.listener.port_range.max = ${toString ports.rabbitmqDistribution}
  '';

  # Firecrawl's auxiliary worker health servers call listen(port) without a
  # host. Keep those inherited Node listeners on the same loopback address as
  # the main API while retaining host networking for OmniRoute access.
  bindLoopback = pkgs.writeText "firecrawl-bind-loopback.cjs" ''
    const net = require("node:net");
    const originalListen = net.Server.prototype.listen;
    const host = process.env.HOST || "127.0.1.1";

    net.Server.prototype.listen = function (...args) {
      const endpoint = args[0];
      const isPort =
        typeof endpoint === "number" ||
        (typeof endpoint === "string" && /^\d+$/.test(endpoint));

      if (isPort && (args.length === 1 || typeof args[1] === "function")) {
        args.splice(1, 0, host);
      } else if (
        endpoint &&
        typeof endpoint === "object" &&
        Object.hasOwn(endpoint, "port") &&
        !Object.hasOwn(endpoint, "host")
      ) {
        args[0] = { ...endpoint, host };
      }

      return originalListen.apply(this, args);
    };
  '';

  commonOptions = [
    "--network=host"
    "--cap-drop=all"
    "--security-opt=no-new-privileges"
  ];

  dependencyUnits = [
    "podman-firecrawl-playwright.service"
    "podman-firecrawl-redis.service"
    "podman-firecrawl-rabbitmq.service"
    "podman-firecrawl-postgres.service"
  ];

  waitForDependencies = pkgs.writeShellScript "wait-for-firecrawl-dependencies" ''
    set -eu

    wait_for_port() {
      name="$1"
      port="$2"
      for attempt in {1..120}; do
        if ${lib.getExe pkgs.netcat-openbsd} -z -w 1 ${address} "$port"; then
          return 0
        fi
        ${lib.getExe' pkgs.coreutils "sleep"} 0.5
      done
      echo "Timed out waiting for Firecrawl $name on ${address}:$port" >&2
      exit 1
    }

    wait_for_port Playwright ${toString ports.playwright}
    wait_for_port Redis ${toString ports.redis}
    wait_for_port RabbitMQ ${toString ports.rabbitmq}
    wait_for_port PostgreSQL ${toString ports.postgres}
  '';

in
{
  config = lib.mkIf (cfg.enable && cfg.enableFirecrawl) {
    assertions = [
      {
        assertion = cfg.enableOmniRoute;
        message = "Firecrawl requires _custom.services.ai.enableOmniRoute.";
      }
    ];

    _custom.services.web-proxies.firecrawl = {
      enable = true;
      subdomain = "firecrawl";
      serviceName = "podman-firecrawl-api";
      publicPort = 20900;
      backendPort = 20901;
      lazy = true;
    };

    virtualisation.oci-containers.containers = {
      firecrawl-api = {
        image = cfg.firecrawlImage;
        cmd = [
          "node"
          "dist/src/harness.js"
          "--start-docker"
        ];
        environment = {
          HOST = address;
          NODE_OPTIONS = "--require=/etc/firecrawl/bind-loopback.cjs";
          PORT = toString proxy.backendPort;
          EXTRACT_WORKER_PORT = toString ports.extractWorker;
          WORKER_PORT = toString ports.worker;
          NUQ_WORKER_PORT = toString ports.nuqWorker;
          NUQ_WORKER_START_PORT = toString ports.nuqWorkerStart;
          NUQ_WORKER_COUNT = "5";
          NUQ_PREFETCH_WORKER_PORT = toString ports.nuqPrefetchWorker;
          NUQ_RECONCILER_WORKER_PORT = toString ports.nuqReconcilerWorker;
          ENV = "local";
          LOGGING_LEVEL = "info";
          USE_DB_AUTHENTICATION = "false";
          REDIS_URL = "redis://${address}:${toString ports.redis}";
          REDIS_RATE_LIMIT_URL = "redis://${address}:${toString ports.redis}";
          PLAYWRIGHT_MICROSERVICE_URL = "http://${address}:${toString ports.playwright}/scrape";
          POSTGRES_HOST = address;
          POSTGRES_PORT = toString ports.postgres;
          POSTGRES_DB = "postgres";
          POSTGRES_USER = "firecrawl";
          POSTGRES_PASSWORD = "firecrawl";
          NUQ_BACKEND = "pg";
          NUQ_DATABASE_URL = postgresUrl;
          NUQ_DATABASE_URL_LISTEN = postgresUrl;
          NUQ_RABBITMQ_URL = "amqp://firecrawl:firecrawl@${address}:${toString ports.rabbitmq}";
          HARNESS_STARTUP_TIMEOUT_MS = "120000";
        };
        volumes = [ "${bindLoopback}:/etc/firecrawl/bind-loopback.cjs:ro" ];
        environmentFiles = [
          config.sops.templates."firecrawl-omniroute.env".path
        ]
        ++ lib.optional (cfg.firecrawlEnvironmentFile != null) cfg.firecrawlEnvironmentFile;
        extraOptions = commonOptions ++ [ "--pids-limit=2048" ];
      };

      firecrawl-playwright = {
        image = cfg.firecrawlPlaywrightImage;
        ports = [ "${address}:${toString ports.playwright}:${toString ports.playwright}" ];
        environment = {
          PORT = toString ports.playwright;
          MAX_CONCURRENT_PAGES = "10";
        };
        # The upstream service always listens on all container interfaces, so
        # publish it through Podman's bridge on loopback instead of host networking.
        extraOptions = (lib.remove "--network=host" commonOptions) ++ [
          "--pids-limit=1024"
          "--shm-size=2g"
          "--tmpfs=/tmp/.cache:rw,noexec,nosuid,nodev,size=1g"
        ];
      };

      firecrawl-redis = {
        image = cfg.firecrawlRedisImage;
        user = "999:999";
        cmd = [
          "redis-server"
          "--bind"
          address
          "--port"
          (toString ports.redis)
          "--appendonly"
          "yes"
          "--dir"
          "/data"
        ];
        volumes = [ "/var/lib/firecrawl/redis:/data:rw" ];
        extraOptions = commonOptions ++ [ "--pids-limit=256" ];
      };

      firecrawl-rabbitmq = {
        image = cfg.firecrawlRabbitmqImage;
        user = "100:101";
        cmd = [ "rabbitmq-server" ];
        environment = {
          RABBITMQ_DEFAULT_USER = "firecrawl";
          RABBITMQ_DEFAULT_PASS = "firecrawl";
          RABBITMQ_NODENAME = "rabbit@firecrawl-rabbitmq";
          ERL_EPMD_ADDRESS = address;
          ERL_EPMD_PORT = toString ports.rabbitmqEpmd;
        };
        volumes = [
          "/var/lib/firecrawl/rabbitmq:/var/lib/rabbitmq:rw"
          "${rabbitmqConfig}:/etc/rabbitmq/rabbitmq.conf:ro"
        ];
        extraOptions = commonOptions ++ [
          "--hostname=firecrawl-rabbitmq"
          "--pids-limit=512"
        ];
      };

      firecrawl-postgres = {
        image = cfg.firecrawlPostgresImage;
        user = "999:999";
        cmd = [
          "postgres"
          "-c"
          "listen_addresses=${address}"
          "-c"
          "port=${toString ports.postgres}"
        ];
        environment = {
          POSTGRES_DB = "postgres";
          POSTGRES_USER = "firecrawl";
          POSTGRES_PASSWORD = "firecrawl";
          PGDATA = "/var/lib/postgresql/data/pgdata";
        };
        volumes = [ "/var/lib/firecrawl/postgres:/var/lib/postgresql/data:rw" ];
        extraOptions = commonOptions ++ [ "--pids-limit=512" ];
      };
    };

    sops.templates."firecrawl-omniroute.env" = {
      mode = "0400";
      restartUnits = [ "podman-firecrawl-api.service" ];
      content = ''
        OPENAI_BASE_URL=http://${address}:${toString config._custom.services.web-proxies.omniroute.publicPort}/v1
        OPENAI_API_KEY=${config.sops.placeholder.local-omniroute-secret-key}
        MODEL_NAME=${cfg.firecrawlModel}
        MODEL_EMBEDDING_NAME=${cfg.firecrawlEmbeddingModel}
      '';
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/firecrawl 0750 root root -"
      "d /var/lib/firecrawl/postgres 0700 999 999 -"
      "d /var/lib/firecrawl/redis 0700 999 999 -"
      "d /var/lib/firecrawl/rabbitmq 0700 100 101 -"
    ];

    systemd.services = {
      podman-firecrawl-api = {
        requires = dependencyUnits ++ [ "podman-omniroute.service" ];
        after = dependencyUnits ++ [ "podman-omniroute.service" ];
        serviceConfig = {
          ExecStartPre = [ waitForDependencies ];
          Restart = "on-failure";
          RestartSec = 2;
          TimeoutStartSec = lib.mkForce 180;
          TimeoutStopSec = lib.mkForce 60;
          UMask = "0077";
          ProtectHome = true;
        };
      };

      podman-firecrawl-playwright = {
        wantedBy = lib.mkForce [ ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 2;
          TimeoutStopSec = lib.mkForce 45;
          ProtectHome = true;
        };
      };

      podman-firecrawl-redis = {
        wantedBy = lib.mkForce [ ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 2;
          TimeoutStopSec = lib.mkForce 45;
          ProtectHome = true;
        };
      };

      podman-firecrawl-rabbitmq = {
        wantedBy = lib.mkForce [ ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 2;
          TimeoutStopSec = lib.mkForce 60;
          ProtectHome = true;
        };
      };

      podman-firecrawl-postgres = {
        wantedBy = lib.mkForce [ ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 2;
          TimeoutStopSec = lib.mkForce 60;
          ProtectHome = true;
        };
      };
    };
  };
}
