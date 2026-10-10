{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config._custom.services.tt;
  ttPackages = inputs.tt.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ./daemon.nix
    ./server.nix
    ./hooks.nix
  ];

  options._custom.services.tt = {
    enable = lib.mkEnableOption "tt task and time tracker";
    package = lib.mkOption {
      type = lib.types.package;
      default = ttPackages.tt;
      description = "Package with the `tt` CLI/daemon and `tt-server`.";
    };
    webPackage = lib.mkOption {
      type = lib.types.package;
      default = ttPackages.tt-web;
      description = "Static web bundle served by `tt-server serve --web-dir`.";
    };
    caCert = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = "${pkgs._custom.wochap-ssc}/rootCA.pem";
      defaultText = lib.literalExpression ''"''${pkgs._custom.wochap-ssc}/rootCA.pem"'';
      description = ''
        Extra CA the client trusts on top of the webpki roots: the mkcert CA
        that signed the nginx vhosts. The daemon stores it as `server.ca_cert`
        in config.toml on every start; it is also `$TT_CA_CERT` for
        `tt login --ca-cert`. null leaves `server.ca_cert` alone.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # On PATH for hooks, quickshell (`tt watch`) and the shell
    _custom.hm.home.packages = [ cfg.package ];
    # `tt login https://tt.<domain> --ca-cert "$TT_CA_CERT"`; tt itself ignores it
    _custom.hm.home.sessionVariables = lib.mkIf (cfg.caCert != null) {
      TT_CA_CERT = toString cfg.caCert;
    };
  };
}
