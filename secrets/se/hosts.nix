{ config, pkgs, lib, ... }:

{
  config = {
    networking.hosts = {
      "54.152.121.219" = [
        "elasticsearch_private.vizualist.com"
        "mongodb_private.vizualist.com"
        "redis_private.vizualist.com"
        "psql_private.vizualist.com"
        "mysql_private.vizualist.com"
      ];
      "52.91.74.86" = [
        "dev-elasticsearch.vizualist.com"
        "dev.mongodb_private.vizualist.com"
        "dev.redis_private.vizualist.com"
        "dev.psql_private.vizualist.com"
        "dev.mysql_private.vizualist.com"
      ];
    };
  };
}
