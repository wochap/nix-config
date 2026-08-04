{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.desktop.mail;

  notmuch = "${pkgs.notmuch}/bin/notmuch";
  jq = "${pkgs.jq}/bin/jq";

  escape = lib.replaceStrings [ "'" ] [ "'\\''" ];

  # One guarded block per entry: for every new message matching the from
  # glob, run the command once with id/From/Subject/Date as $1..$4 and the
  # full message text on stdin. `|| true` keeps a failing user command from
  # failing `notmuch new` (and with it the sync unit that invoked it).
  # NOTE: `search --output=messages` emits ids already prefixed with "id:",
  # so MAIL_ID is used as-is in queries.
  arriveBlock = h: ''
    # mail arrive hook (from:${h.from})
    while IFS= read -r MAIL_ID; do
      [ -n "$MAIL_ID" ] || continue
      # json shape: [thread] > [message, replies] > message object
      meta="$(${notmuch} show --format=json "$MAIL_ID" \
        | ${jq} -r '.[0][0][0] | [.headers.From // "", .headers.Subject // "", .headers.Date // ""] | @tsv')"
      IFS=$'\t' read -r MAIL_FROM MAIL_SUBJECT MAIL_DATE <<< "$meta"
      export MAIL_ID MAIL_FROM MAIL_SUBJECT MAIL_DATE
      ${notmuch} show --format=text "$MAIL_ID" | {
        ${h.command} "$MAIL_ID" "$MAIL_FROM" "$MAIL_SUBJECT" "$MAIL_DATE"
      } || true
    done < <(${notmuch} search --output=messages 'tag:new and from:${escape h.from}')
  '';
in
{
  config = lib.mkIf (cfg.enable && cfg.hooks.arrive != [ ]) {
    _custom.hm.programs.notmuch.hooks.postNew = lib.concatMapStringsSep "\n" arriveBlock cfg.hooks.arrive;
  };
}
