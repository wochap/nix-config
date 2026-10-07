{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.services.tt;
  jq = lib.getExe pkgs.jq;
  notifySend = lib.getExe' pkgs.libnotify "notify-send";

  notifyHooks = {
    "entry.started.d/50-notify" = ''
      [ "$TT_ORIGIN" = local ] || exit 0
      title=$(${jq} -r '"#\(.task.seq) \(.task.title)"')
      ${notifySend} -a tt "Started" "$title"
    '';
    "entry.stopped.d/50-notify" = ''
      [ "$TT_ORIGIN" = local ] || exit 0
      body=$(${jq} -r '(.entry.duration // 0) as $d
        | "#\(.task.seq) \(.task.title)\n\($d / 3600 | floor)h \($d % 3600 / 60 | floor)m"')
      ${notifySend} -a tt "Stopped" "$body"
    '';
  };

  mkHook = name: text: {
    source = pkgs.writeShellScript "tt-hook-${lib.strings.sanitizeDerivationName name}" text;
  };
in
{
  options._custom.services.tt = {
    notify = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "notify-send when an entry starts or stops on this host.";
    };
    hooks = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      example = {
        "all.d/log" = ''cat >> "$HOME/.local/state/tt/events.ndjson"'';
      };
      description = ''
        Shell hooks, keyed by path under ~/.config/tt/hooks (e.g.
        `entry.started.d/20-foo`). The event JSON arrives on stdin, `TT_EVENT`,
        `TT_ORIGIN` and `TT_SEQ` in the environment; see docs/hooks.md in tt.
        config.toml stays unmanaged: `tt login` writes the token into it.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    _custom.hm.xdg.configFile = lib.mapAttrs' (
      name: text: lib.nameValuePair "tt/hooks/${name}" (mkHook name text)
    ) ((lib.optionalAttrs cfg.notify notifyHooks) // cfg.hooks);
  };
}
