{ inputs, lib, pkgs, ... }:

rec {
  fromYAML = pkgs.callPackage ./from-yaml { };

  unwrapHex = str: builtins.substring 1 (builtins.stringLength str) str;

  capitalize = str:
    if builtins.stringLength str == 0 then
      ""
    else
      let
        firstChar = builtins.substring 0 1 str;
        restOfString = builtins.substring 1 (-1) str;
      in (lib.toUpper firstChar) + restOfString;

  runtimePath = runtimeRoot: path:
    let
      rootStr = toString inputs.self;
      pathStr = toString path;
    in assert lib.assertMsg (lib.hasPrefix rootStr pathStr)
      "${pathStr} does not start with ${rootStr}";
    runtimeRoot + lib.removePrefix rootStr pathStr;

  # TODO: use hmConfig.lib.file.mkOutOfStoreSymlink
  mkOutOfStoreSymlink = path:
    let
      pathStr = toString path;
      name = lib.home-manager.strings.storeFileName (baseNameOf pathStr);
    in pkgs.runCommandLocal name { } "ln -s ${lib.escapeShellArg pathStr} $out";

  # source: https://github.com/nix-community/home-manager/issues/257#issuecomment-1646557848
  relativeSymlink = configDirectory: path:
    mkOutOfStoreSymlink (runtimePath configDirectory path);

  # generates xdg.configFile attributes for a directory's top-level items
  linkContents = targetDir: sourceDir:
    let
      files = builtins.readDir sourceDir;
      fileAttrs = lib.mapAttrs'
        (name: _: lib.nameValuePair name { source = "${sourceDir}/${name}"; })
        files;
    in lib.mapAttrs'
    (name: value: lib.nameValuePair "${targetDir}/${name}" value) fileAttrs;

  mkWaylandService = lib.recursiveUpdate {
    Unit.PartOf = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      Slice = "app-graphical.slice";
      ExecCondition = [
        ''
          ${pkgs.systemd}/lib/systemd/systemd-xdg-autostart-condition "dwl:Hyprland:wlroots:sway:Wayfire:labwc" ""''
      ];
    };
  };

  mkGraphicalService = lib.recursiveUpdate {
    Unit.PartOf = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
    Install.WantedBy = [ "graphical-session.target" ];
    Service.Slice = "app-graphical.slice";
  };
}
