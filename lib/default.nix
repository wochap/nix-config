{ inputs, lib, pkgs, ... }:

rec {
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

  relativeSymlink = configDirectory: path:
    mkOutOfStoreSymlink (runtimePath configDirectory path);
}
