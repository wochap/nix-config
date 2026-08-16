{
  inputs,
  lib,
  pkgs,
  ...
}:

rec {
  fromYAML = pkgs.callPackage ./from-yaml { };

  unwrapHex = str: builtins.substring 1 (builtins.stringLength str) str;

  capitalize =
    str:
    if builtins.stringLength str == 0 then
      ""
    else
      let
        firstChar = builtins.substring 0 1 str;
        restOfString = builtins.substring 1 (-1) str;
      in
      (lib.toUpper firstChar) + restOfString;

  runtimePath =
    runtimeRoot: path:
    let
      rootStr = toString inputs.self;
      pathStr = toString path;
    in
    assert lib.assertMsg (lib.hasPrefix rootStr pathStr) "${pathStr} does not start with ${rootStr}";
    runtimeRoot + lib.removePrefix rootStr pathStr;

  # TODO: use hmConfig.lib.file.mkOutOfStoreSymlink
  mkOutOfStoreSymlink =
    path:
    let
      pathStr = toString path;
      name = lib.home-manager.strings.storeFileName (baseNameOf pathStr);
    in
    pkgs.runCommandLocal name { } "ln -s ${lib.escapeShellArg pathStr} $out";

  # NOTE: it doesn't work if you add `executable = true;`
  # source: https://github.com/nix-community/home-manager/issues/257#issuecomment-1646557848
  relativeSymlink = configDirectory: path: mkOutOfStoreSymlink (runtimePath configDirectory path);

  # generates xdg.configFile attributes for a directory's top-level items
  linkContents =
    targetDir: sourceDir:
    let
      files = builtins.readDir sourceDir;
      fileAttrs = lib.mapAttrs' (
        name: _: lib.nameValuePair name { source = "${sourceDir}/${name}"; }
      ) files;
    in
    lib.mapAttrs' (name: value: lib.nameValuePair "${targetDir}/${name}" value) fileAttrs;

  mkWaylandService = lib.recursiveUpdate {
    Unit.PartOf = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      Slice = "app-graphical.slice";
      ExecCondition = [
        ''${pkgs.systemd}/lib/systemd/systemd-xdg-autostart-condition "dwl:Hyprland:wlroots:sway:Wayfire:labwc" ""''
      ];
    };
  };

  mkGraphicalService = lib.recursiveUpdate {
    Unit.PartOf = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
    Install.WantedBy = [ "graphical-session.target" ];
    Service.Slice = "app-graphical.slice";
  };

  # Filesystem, device, and syscall exceptions stay service-local.
  strictNetworkService = {
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateTmp = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    CapabilityBoundingSet = "";
    AmbientCapabilities = "";
    SystemCallArchitectures = "native";
    UMask = "0077";
  };

  # Callers must explicitly expose each required home path.
  userServiceHardening = {
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateTmp = true;
    ProtectSystem = "strict";
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    CapabilityBoundingSet = "";
    AmbientCapabilities = "";
    SystemCallArchitectures = "native";
    UMask = "0077";

    # User-owned SOPS secrets need masking from unrelated user units.
    # Credentialed units bind back only their required files.
    TemporaryFileSystem = [ "/run/secrets:ro" ];
  };

  # Minimal mount namespace for services that otherwise run without the
  # general sandbox. Callers bind back only the SOPS files they require.
  userServiceSecretIsolation = {
    TemporaryFileSystem = [ "/run/secrets:ro" ];
  };

  # Use as a systemd ExecCondition for network-bound services. A failed
  # ExecCondition skips the run without putting the unit in the failed state,
  # so OnFailure handlers do not notify about expected offline runs.
  mkNetworkCheckScript =
    name: hosts:
    pkgs.writeShellScript name ''
      ${lib.concatMapStringsSep "\n" (host: ''
        if ${pkgs.coreutils}/bin/timeout 10 ${pkgs.systemd}/bin/resolvectl query --legend=no ${lib.escapeShellArg host} >/dev/null 2>&1; then
          exit 0
        fi'') hosts}
      exit 1
    '';
}
