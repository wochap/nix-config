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

  accountFolder = name: acc: if acc.sync == "lieer" then "${name}/mail" else "${name}/INBOX";

  # Hook failures must not fail notmuch new and its parent sync unit.
  arriveBlock = name: acc: h: ''
    # mail arrive hook (account:${name} from:${h.from})
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
    done < <(${notmuch} search --output=messages 'tag:new and from:${escape h.from} and folder:${accountFolder name acc}')
  '';

  postNewHook = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: acc: lib.concatMapStringsSep "\n" (arriveBlock name acc) acc.hooks.arrive
    ) cfg.accounts
  );
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (acc: acc.sync != "none" || acc.hooks.arrive == [ ]) (
          lib.attrValues cfg.accounts
        );
        message = "_custom.desktop.mail.accounts.<name>.hooks.arrive requires sync = \"lieer\" or \"mbsync\" — mail of sync = \"none\" accounts is never imported, so hooks could never fire.";
      }
    ];

    _custom.hm.programs.notmuch.hooks.postNew = lib.mkIf (postNewHook != "") postNewHook;
  };
}
