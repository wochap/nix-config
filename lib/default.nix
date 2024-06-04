{ inputs, lib, pkgs, ... }:

rec {
  fromYAML = pkgs.callPackage ./from-yaml { };

  unwrapHex = str: builtins.substring 1 (builtins.stringLength str) str;

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

  mkWaylandService = lib.recursiveUpdate {
    Unit.PartOf = [ "wayland-session.target" ];
    Unit.After = [ "wayland-session.target" ];
    Install.WantedBy = [ "wayland-session.target" ];
  };

  mkGraphicalService = lib.recursiveUpdate {
    Unit.PartOf = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
