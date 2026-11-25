{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config._custom.services.pcscd;
  openscPkcs11 = "${pkgs.opensc}/lib/opensc-pkcs11.so";
in
{
  options._custom.services.pcscd.enable = lib.mkEnableOption { };

  config = lib.mkIf cfg.enable {
    services.pcscd.enable = true;

    environment.systemPackages = with pkgs; [
      pcsc-tools
      opensc
      nssTools
    ];

    environment.etc."pkcs11/modules/opensc-pkcs11.module".text = ''
      module: ${openscPkcs11}
    '';

    _custom.hm = lib.mkIf config._custom.programs.firefox.enable {
      programs.firefox.policies.SecurityDevices = {
        "OpenSC PKCS#11" = openscPkcs11;
      };
    };
  };
}
