{ config, lib, options, ... }:

let inherit (config._custom.globals) userName homeDirectory;
in {
  options = {
    _custom.hm = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Options to pass directly to home-manager primary user.";
    };

    _custom.user = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description =
        "Options to pass directly to users.extraUsers primary user.";
    };
  };

  config = {
    _custom.user.home = homeDirectory;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = false;
    home-manager.backupFileExtension = "hm-bak";

    _custom.hm = {
      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      # Home Manager needs a bit of information about you and the
      # paths it should manage.
      home.username = userName;
      home.homeDirectory = homeDirectory;

      programs.bash.enable = true;

      # Prevent home-manager service to fail
      # https://discourse.nixos.org/t/way-to-automatically-override-home-manager-collisions/33038/3
      xdg.configFile."gtk-4.0/gtk.css".force = true;
      xdg.configFile."gtk-4.0/settings.ini".force = true;
      xdg.configFile."gtk-3.0/gtk.css".force = true;
      xdg.configFile."gtk-3.0/settings.ini".force = true;
    };

    # hm -> home-manager.users.<primary user>
    home-manager.users.${userName} = lib.mkAliasDefinitions options._custom.hm;

    # user -> users.extraUsers.<primary user>
    users.extraUsers.${userName} = lib.mkAliasDefinitions options._custom.user;
  };
}
