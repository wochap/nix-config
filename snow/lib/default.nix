{ lib, inputs, ... }:

rec {
  unwrapHex = str: builtins.substring 1 (builtins.stringLength str) str;

  # https://github.com/nix-community/home-manager/issues/257#issuecomment-1646557848
  runtimePath = runtimeRoot: path:
    let
      rootStr = toString inputs.self;
      pathStr = toString path;
    in assert lib.assertMsg (lib.hasPrefix rootStr pathStr)
      "${pathStr} does not start with ${rootStr}";
    runtimeRoot + lib.removePrefix rootStr pathStr;
}

