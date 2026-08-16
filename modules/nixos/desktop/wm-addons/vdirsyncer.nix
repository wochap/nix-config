{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  calendarCfg = config._custom.desktop.calendar;
  contactsCfg = config._custom.desktop.contacts;
  sopsEnabled = config._custom.security.sops.enable;
  inherit (config._custom.globals) userName isSandbox;
  hmConfig = config.home-manager.users.${userName};
  inherit (hmConfig.xdg) configHome dataHome;

  calendarAccounts = lib.optionalAttrs calendarCfg.enable calendarCfg.accounts;
  contactAccounts = lib.optionalAttrs contactsCfg.enable contactsCfg.accounts;
  calendarActive = calendarAccounts != { };
  contactsActive = contactAccounts != { };
  active = calendarActive || contactsActive;

  googleCalendarAccounts = lib.filterAttrs (
    _: acc: acc.remote.type == "google_calendar"
  ) calendarAccounts;
  googleContactAccounts = lib.filterAttrs (
    _: acc: acc.remote.type == "google_contacts"
  ) contactAccounts;
  googleActive = googleCalendarAccounts != { } || googleContactAccounts != { };

  personalSopsFile = ../../../../secrets-sops/personal.yaml;
  clientIdPath = config.sops.secrets."personal-vdirsyncer-client-id".path;
  clientSecretPath = config.sops.secrets."personal-vdirsyncer-client-secret".path;
  cat = "${pkgs.coreutils}/bin/cat";

  davAccounts =
    lib.attrValues (lib.filterAttrs (_: acc: acc.remote.type == "caldav") calendarAccounts)
    ++ lib.attrValues (lib.filterAttrs (_: acc: acc.remote.type == "carddav") contactAccounts);
  davPasswordFiles = map (acc: acc.remote.passwordFile) davAccounts;
  davCertificateFiles = lib.filter (path: path != null) (map (acc: acc.remote.verify) davAccounts);

  mkRemote =
    acc:
    {
      inherit (acc.remote) type;
    }
    //
      lib.optionalAttrs
        (lib.elem acc.remote.type [
          "caldav"
          "carddav"
        ])
        {
          inherit (acc.remote) url userName;
          passwordCommand = [
            cat
            acc.remote.passwordFile
          ];
        };

  mkVdirsyncer =
    acc:
    {
      enable = true;
      inherit (acc)
        collections
        conflictResolution
        metadata
        ;
    }
    //
      lib.optionalAttrs
        (lib.elem acc.remote.type [
          "google_calendar"
          "google_contacts"
        ])
        {
          inherit (acc) tokenFile;
          clientIdCommand = [
            cat
            clientIdPath
          ];
          clientSecretCommand = [
            cat
            clientSecretPath
          ];
        }
    //
      lib.optionalAttrs
        (lib.elem acc.remote.type [
          "caldav"
          "carddav"
        ])
        {
          inherit (acc.remote)
            auth
            verify
            verifyFingerprint
            ;
        };
in
{
  config = lib.mkIf active {
    nixpkgs.overlays = [
      (_final: prev: {
        vdirsyncer = prev.vdirsyncer.overrideAttrs (_oldAttrs: {
          version = "0.20.0+g${inputs.vdirsyncer.shortRev or "dirty"}";
          src = inputs.vdirsyncer;
        });
      })
    ];

    assertions = [
      {
        assertion = !googleActive || (sopsEnabled && !isSandbox);
        message = "Google vdirsyncer accounts require _custom.security.sops.enable and are unavailable in sandbox configurations.";
      }
    ];

    sops.secrets = lib.mkIf (googleActive && sopsEnabled && !isSandbox) {
      "personal-vdirsyncer-client-id" = {
        owner = userName;
        sopsFile = personalSopsFile;
      };
      "personal-vdirsyncer-client-secret" = {
        owner = userName;
        sopsFile = personalSopsFile;
      };
    };

    _custom.desktop.networking.userUnitsOnConnect = [ "vdirsyncer.service" ];

    _custom.hm = {
      accounts.calendar = lib.mkIf calendarActive {
        basePath = "${dataHome}/vdirsyncer";
        accounts = lib.mapAttrs' (
          _: acc:
          lib.nameValuePair acc.name {
            primary = acc.primary && acc.primaryCollection != null;
            inherit (acc) primaryCollection;
            local = {
              path = acc.localPath;
              type = "filesystem";
              fileExt = ".ics";
            };
            remote = mkRemote acc;
            vdirsyncer = mkVdirsyncer acc;
            khal = {
              enable = true;
              type = "discover";
              inherit (acc)
                glob
                color
                readOnly
                ;
            };
          }
        ) calendarAccounts;
      };

      accounts.contact = lib.mkIf contactsActive {
        basePath = "${dataHome}/vdirsyncer";
        accounts = lib.mapAttrs' (
          _: acc:
          lib.nameValuePair acc.name {
            local = {
              path = acc.localPath;
              type = "filesystem";
              fileExt = ".vcf";
            };
            remote = mkRemote acc;
            vdirsyncer = mkVdirsyncer acc;
          }
        ) contactAccounts;
      };

      programs.vdirsyncer.enable = true;

      services.vdirsyncer = {
        enable = true;
        frequency = if calendarActive then calendarCfg.frequency else contactsCfg.frequency;
      };

      systemd.user.services.vdirsyncer = {
        Unit = {
          OnFailure = "vdirsyncer-on-failure.service";
          OnSuccess = lib.mkIf calendarActive "ics2rem.service";
        };
        Service = lib._custom.userServiceHardening // {
          ExecCondition = "${lib._custom.mkNetworkCheckScript "vdirsyncer-network-check" [
            "one.one.one.one"
          ]}";
          ProtectHome = "tmpfs";
          BindReadOnlyPaths = lib.unique (
            [ "${configHome}/vdirsyncer/config" ]
            ++ lib.optionals googleActive [
              clientIdPath
              clientSecretPath
            ]
            ++ davPasswordFiles
            ++ davCertificateFiles
          );
          BindPaths = [ "${dataHome}/vdirsyncer" ];
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
        };
      };

      systemd.user.services.vdirsyncer-on-failure.Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.libnotify}/bin/notify-send --app-name vdirsyncer --app-icon apport --icon apport --hint=int:transient:1 'Service failed'";
      };

      systemd.user.timers.vdirsyncer.Timer.Persistent = true;
    };
  };
}
