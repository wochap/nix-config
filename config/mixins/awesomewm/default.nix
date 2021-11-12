{ config, pkgs, lib, ... }:

let
  userName = config._userName;
  nice-repo = builtins.fetchGit {
    url = "https://github.com/mut-ex/awesome-wm-nice.git";
    rev = "810aa72bbebfee15d3375fdcb8d8a09f5c7741c8";
    ref = "master";
  };
  buttons-repo = builtins.fetchGit {
    url = "https://github.com/streetturtle/awesome-buttons.git";
    rev = "810aa72bbebfee15d3375fdcb8d8a09f5c7741c8";
    ref = "master";
  };
  theme-repo = builtins.fetchGit {
    url = "https://github.com/MrJakeSir/dots.git";
    rev = "1ec7190c5f7c94d0c9c8dc823193fb44eea35230";
    ref = "master";
  };
in
{
  config = {
    home-manager.users.${userName} = {
      home.file = {
        # ".config/awesome/rc.lua".source = ./dotfiles/rc.lua;
        # ".config/awesome/nice".source = nice-repo;
        # ".config/awesome/awesome-buttons".source = "${theme-repo}/awesome/awesome-buttons";
        # ".config/awesome/awesome-wm-widgets".source = "${theme-repo}/awesome/awesome-wm-widgets";
        # ".config/awesome/awesome-lain".source = "${theme-repo}/awesome/awesome-lain";
        ".config/awesome".source = "${theme-repo}/awesome==";
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
