{ config, pkgs, lib, ... }:

let
  userName = config._userName;
in
{
  config = {
    home-manager.users.${userName} = {
      home.file = {
        ".config/awesome/rc.lua".source = ./dotfiles/rc.lua;
      };
    };

    services.xserver = {
      windowManager.awesome = {
        enable = true;
        luaModules = with pkgs.luaPackages; [
          luarocks # is the package manager for Lua modules
          luadbi-mysql # Database abstraction layer
        ];
        package = pkgs.awesome.overrideAttrs(o: {
          src = pkgs.fetchFromGitHub {
            repo = "awesome";
            owner = "awesomewm";
            rev = "5ca16ae8a07ec7114aa64b9ed14b741b901acb3a";
            sha256 = "1iv018l79ymhhk8nbbxpbbyqrv6lr2azivfw5v8f29mjn69cl6xg";
          };
        });
      };
    };
  };
}
