{ config, pkgs, lib, ... }:

let cfg = config._custom.programs.lang-qt;
in {
  options._custom.programs.lang-qt.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      brotli # shared lib, required by qmlls
      kdePackages.qtdeclarative # qmlls
    ];

    _custom.hm = {
      home.sessionVariables.QMLLS_BUILD_DIRS = with pkgs;
        "${kdePackages.qtdeclarative}/lib/qt-6/qml/:${config._custom.desktop.quickshell.package}/lib/qt-6/qml/";
    };
  };
}

