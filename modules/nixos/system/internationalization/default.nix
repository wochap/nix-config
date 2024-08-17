{ pkgs, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      nuspell
      hyphen
      hunspell
      hunspellDicts.en_US
      hunspellDicts.es_ES
      hunspellDicts.ru_RU
    ];

    i18n = {
      defaultLocale = "en_US.UTF-8";
      supportedLocales = [
        "C.UTF-8/UTF-8"
        "en_US.UTF-8/UTF-8"
        "es_ES.UTF-8/UTF-8"
        "ru_RU.UTF-8/UTF-8"
      ];
      extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
    };

    # better ls sorting
    _custom.hm.home.language.collate = "C.UTF-8";
  };
}

